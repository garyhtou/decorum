# Decorum Rails Application — Architecture Plan

## Context

Transform the existing Ruby library into a full Rails application supporting online multiplayer gameplay, scenario creation/sharing, solution checking, and leaderboards. The UI should feel native and custom-built — like a polished mobile game on mobile, and a fully responsive desktop experience on larger screens. Not a typical website.

---

## Requirements

### Must Have (MVP)
- Guest play (no account required for gameplay — session-based guest UUID)
- User accounts (required only for leaderboard submission)
- Browse and play built-in scenarios
- Local mode (single device, players pass between turns with "curtain screen")
- Full game rule enforcement (all 5 actions, round marker tracking, hearts, Heart-to-Heart, object supply, pass-only-when-fulfilled)
- Solution checker (configure house, check conditions, per-condition breakdown — no leaderboard)
- Gameplay leaderboard per scenario (points-based, from completed games only)
- Mobile-first responsive design that's equally polished on desktop
- Game UI mirrors the physical game (room grid, object slots, condition cards)
- Inline icons for game keywords with tooltips + accessible glossary panel
- Object supply tracking (4 copies of each of the 12 specific objects = 48 tokens, per PDF)
- Condition secrecy enforcement (other players' conditions never in HTML/DOM/network for wrong player)
- Fulfillment re-checked after EVERY move (not just the acting player's turn)
- "Skip ahead to first Heart-to-Heart" option (both players agree)
- After Heart-to-Heart, shared conditions become visible to recipients

### Must Have (Post-MVP)
- Online multiplayer with ActionCable (invite codes, real-time sync, per-player condition scoping)
- Scenario creator with visual condition builder
- Difficulty analysis (async, cached)
- Game replay (step through moves + events via shared sequence numbers)
- Optional partner comments (toggle for in-person/call play)

### Nice to Have
- Live cursor presence (Figma-style — note: requires Redis-backed ActionCable, not Solid Cable)
- 3/4-player support (House Meeting, roommate tokens, "your room" conditions, Roommate Swap action)
- Spectator mode
- Achievement system
- Social features (friends, challenge invitations)
- Turbo Native mobile app wrapper
- Per-turn time limits (optional setting)
- Undo support (before partner comments)
- Game history/stats on user profiles

---

## Technology Stack

- **Rails 8** with Hotwire (Turbo 8 morphing + Stimulus)
- **PostgreSQL** with JSONB columns for game state
- **ActionCable** for real-time multiplayer (Phase 2 — Solid Cable initially, Redis at ~5K concurrent games)
- **Solid Cache / Solid Queue** (database-backed)
- **Tailwind CSS** for responsive, mobile-first styling
- **Stimulus controllers** for interactions, animations
- **Interact.js** for cross-platform drag-and-drop with touch support
- **Custom SVGs** for game graphics
- **Propshaft + importmap-rails** (Rails 8 default asset pipeline, no esbuild needed)

### Key Gems
- **`aasm`** — State machine for Game (guards, callbacks for event logging + broadcasts)
- **`action_policy`** — Authorization (supports guest contexts, ActionCable channel auth)
- **`pagy`** — Pagination for leaderboards and scenario browsing (Turbo Frame support)
- **`store_model`** — Typed JSONB columns (validation + type safety for `details`, `conditions`, `house_state`)
- **`oj`** — Fast JSON parsing (measurable speedup for solver serialization/deserialization)
- **`rack-attack`** — Middleware-level rate limiting (invite code brute-force, login throttling)
- **`factory_bot_rails` + `faker`** — Test data
- **`cuprite`** — Headless Chrome for system tests (faster than Selenium)

### Why Turbo 8 Morphing

Rails 8 ships with Turbo 8 page morphing (`data-turbo-refresh-method="morph"`). Instead of fine-grained Turbo Stream replacements, the entire page re-renders and Turbo diffs the DOM. This preserves scroll position, focus state, and CSS animations — perfect for a game board that updates on every move.

```html
<head>
  <meta name="turbo-refresh-method" content="morph">
  <meta name="turbo-refresh-scroll" content="preserve">
  <meta name="turbo-cache-control" content="no-cache">  <!-- prevent condition leakage via back button -->
</head>
```

---

## Class Namespacing Convention

Nested namespaced classes for domain concepts:
- `Game::Player`, `Game::Move`, `Game::Comment`, `Game::Event`
- `Scenario::Score`
- Each model sets `self.table_name` explicitly to avoid Zeitwerk inference issues

Top-level controllers stay flat; nested controllers for sub-resources:
- `GamesController`, `ScenariosController`
- `Game::MovesController`, `Scenario::ScoresController`, `Scenario::ChecksController`

---

## Database Schema

```ruby
# users
create_table :users do |t|
  t.string :email_address, null: false, index: { unique: true }
  t.string :password_digest, null: false
  t.string :display_name, null: false, limit: 50
  t.timestamps
end

# scenarios
create_table :scenarios do |t|
  t.string :name, null: false
  t.text :description
  t.string :house_type, null: false
  t.integer :player_count, null: false
  t.jsonb :initial_state, null: false
  t.jsonb :conditions, null: false
  t.references :creator, foreign_key: { to_table: :users, on_delete: :nullify }, null: true
  t.boolean :published, default: false
  t.float :difficulty_score
  t.jsonb :difficulty_report
  t.integer :solution_count
  t.integer :games_completed_count, default: 0
  t.timestamps

  t.index [:published, :created_at], where: "published = true", name: "idx_scenarios_published"
  t.index [:creator_id], where: "creator_id IS NOT NULL", name: "idx_scenarios_creator"
  t.check_constraint "player_count >= 2 AND player_count <= 4"
  t.check_constraint "house_type IN ('two_player', 'four_player')"
end

# games
create_table :games do |t|
  t.references :scenario, null: false, foreign_key: true
  t.string :state, null: false, default: "in_progress"
  t.jsonb :house_state, null: false
  t.integer :current_player_index, default: 0
  t.integer :round_marker, default: 1   # position on track (1-15 for 2P, 1-5 for 3/4P)
  t.integer :total_rounds_played, default: 0
  t.integer :hearts_remaining         # set by before_create callback: 3 for 2P, 5 for 3/4P
  t.integer :heart_to_hearts_held, default: 0
  t.string :mode, null: false
  t.string :team_name, limit: 50
  t.string :invite_code, limit: 8, index: { unique: true }
  t.integer :lock_version, default: 0
  t.integer :moves_count, default: 0  # counter cache
  t.boolean :comments_enabled, default: true
  t.datetime :started_at
  t.datetime :completed_at
  t.datetime :last_activity_at
  t.timestamps

  t.index [:state, :last_activity_at], name: "idx_games_state_activity"
  t.index [:state, :mode], where: "state = 'waiting' AND mode = 'online'", name: "idx_games_joinable"
  t.check_constraint "current_player_index >= 0 AND current_player_index <= 3"
  t.check_constraint "round_marker >= 1"
  t.check_constraint "total_rounds_played >= 0"
  t.check_constraint "hearts_remaining >= 0"
  t.check_constraint "mode IN ('local', 'online')"
  t.check_constraint "state IN ('waiting', 'in_progress', 'completed', 'abandoned')"
end

# game_players (Game::Player)
create_table :game_players do |t|
  t.references :game, null: false, foreign_key: { on_delete: :cascade }
  t.references :user, foreign_key: { on_delete: :nullify }
  t.string :guest_id, limit: 36       # UUID from session cookie (for unauthenticated players)
  t.integer :player_index, null: false
  t.string :display_name, null: false, limit: 50
  t.jsonb :conditions, null: false
  t.boolean :fulfilled, default: false
  t.string :current_bedroom           # 3/4P only
  t.timestamps

  t.index [:game_id, :player_index], unique: true
  t.index [:user_id], where: "user_id IS NOT NULL", name: "idx_game_players_user"
  t.index [:guest_id], where: "guest_id IS NOT NULL", name: "idx_game_players_guest"
  t.check_constraint "player_index >= 0 AND player_index <= 3"
end

# game_moves (Game::Move)
create_table :game_moves do |t|
  t.references :game, null: false, foreign_key: { on_delete: :cascade }
  t.references :game_player, null: false, foreign_key: { on_delete: :cascade }
  t.integer :sequence_number, null: false  # shared counter with events for replay interleaving
  t.integer :round_marker, null: false
  t.integer :total_rounds_played, null: false
  t.string :action_type, null: false
  t.jsonb :details, null: false
  t.jsonb :house_state_after, null: false
  t.datetime :created_at, null: false

  t.index [:game_id, :sequence_number], unique: true, name: "idx_moves_game_sequence"
  t.check_constraint "sequence_number >= 1"
end

# game_comments (Game::Comment)
create_table :game_comments do |t|
  t.references :game_move, null: false, foreign_key: { on_delete: :cascade }
  t.references :game_player, null: false, foreign_key: { on_delete: :cascade }
  t.string :sentiment, null: false
  t.datetime :created_at, null: false

  t.check_constraint "sentiment IN ('positive', 'negative', 'neutral')"
end

# game_events (Game::Event) — non-move events for full replay
create_table :game_events do |t|
  t.references :game, null: false, foreign_key: { on_delete: :cascade }
  t.references :game_player, foreign_key: { on_delete: :cascade }  # nullable, for player-specific events
  t.integer :sequence_number, null: false  # shared counter with moves
  t.string :event_type, null: false
  t.jsonb :details, null: false
  t.datetime :created_at, null: false

  t.index [:game_id, :sequence_number], name: "idx_events_game_sequence"
  t.index [:game_id, :created_at], name: "idx_events_game_timeline"
end

# scenario_scores (Scenario::Score)
create_table :scenario_scores do |t|
  t.references :scenario, null: false, foreign_key: true
  t.references :game, null: false, foreign_key: true
  t.references :user, foreign_key: { on_delete: :nullify }
  t.string :team_name, limit: 50
  t.integer :points, null: false
  t.integer :conditions_met, null: false
  t.integer :total_conditions, null: false
  t.integer :rounds_used, null: false
  t.integer :hearts_remaining, null: false
  t.datetime :completed_at, null: false
  t.timestamps

  t.index [:scenario_id, :points, :rounds_used, :completed_at],
    order: { points: :desc, rounds_used: :asc, completed_at: :asc },
    name: "idx_leaderboard"
  t.index [:game_id], unique: true, name: "idx_scores_game_unique"
  t.check_constraint "points >= 0"
  t.check_constraint "conditions_met >= 0 AND conditions_met <= total_conditions"
end
```

### Shared Sequence Numbers

Moves and events share a `sequence_number` counter per game for accurate replay interleaving. Computed as `game.moves.count + game.events.count + 1` within the same transaction, protected by optimistic locking.

### `last_activity_at` Updates

Updated via raw SQL (`Game.where(id:).update_all(last_activity_at: Time.current)`) to avoid incrementing `lock_version` and causing spurious `StaleObjectError` on concurrent move submissions.

---

## Authentication: Guest Sessions + Accounts

**Dual-session model:**

1. **Guest sessions**: Rails encrypted cookie with a `guest_id` (SecureRandom UUID). No database record. Tracks which `game_player` records the guest "owns."
2. **Authenticated sessions**: Rails 8 auth generator (`Session` model with `user_id`). Used for leaderboard submission.
3. **Bridge**: When a guest creates an account, link their existing `game_player` records by setting `user_id`.

```ruby
class Current < ActiveSupport::CurrentAttributes
  attribute :session, :user, :guest_id

  def identified?
    user.present? || guest_id.present?
  end
end
```

The curtain screen's "current viewing player" is stored in the encrypted cookie session (not database) since it changes on every turn handoff.

---

## Game Rule Enforcement

### Action Validation (Game::Engine)

Each action type uses the command pattern with a registry:

```ruby
module Actions
  REGISTRY = {
    "add_object" => Actions::AddObject,
    "remove_object" => Actions::RemoveObject,
    "swap_object" => Actions::SwapObject,
    "paint_wall" => Actions::PaintWall,
    "pass" => Actions::Pass,
    "roommate_swap" => Actions::RoommateSwap,
  }.freeze
end
```

**Swap validation specifics:**
- Slot must be currently filled
- New object must be different from current
- New object must be a valid combination for that type
- New object must be available in supply

**Pass validation:** Player's fulfillment status must be `true`. Fulfillment is re-checked after every move (any player's action can change another player's fulfillment).

**Comment validation:**
- 2P: exactly one comment per move, from the non-acting player
- 3/4P: multiple comments allowed, each from a non-acting player, at most one per commenter

### Move Idempotency (online mode)

Requests include `expected_sequence_number`. If `game.next_sequence_number == expected`, process the move. If `game.next_sequence_number > expected`, the move was already processed — return current state. Prevents duplicate moves from network retries.

### Heart-to-Heart Visibility

After a Heart-to-Heart, shared conditions become visible to recipients. The server tracks this via `Game::Event` with `event_type: :heart_to_heart`. When rendering a player's view, the controller queries heart-to-heart events and includes conditions shared WITH that player (from other players' cards). This is the one exception to "never send other players' conditions."

### "Skip Ahead" to First Heart-to-Heart

Both players can propose skipping ahead. Modeled as a `Game::Event` with `event_type: :skip_proposed`. If both players agree (tracked via event details), the Heart-to-Heart triggers immediately.

---

## Condition Secrecy

### Local Mode: "Curtain Screen"

1. Server ONLY sends current viewing player's conditions + any conditions shared with them via Heart-to-Heart
2. Handoff screen between turns contains no game state
3. Server-side session variable tracks current viewer
4. Turbo cache disabled on game pages (`<meta name="turbo-cache-control" content="no-cache">`) to prevent back-button leakage

### Online Mode (Phase 2): Per-Player Scoping

Shared ActionCable stream for public info only (house state, moves, turn info). Each player fetches their own conditions via a separate authenticated HTTP endpoint. Conditions are NEVER in ActionCable broadcasts.

```ruby
# Broadcast public game state to all players
Turbo::StreamsChannel.broadcast_replace_to(game, target: "game_board", ...)

# Each player fetches their own conditions via:
# GET /games/:id/my_conditions (scoped to current_game_player)
```

---

## Zeitwerk Autoloading Migration

The existing library uses `Dir.glob` + `require_relative` which breaks under Zeitwerk. Required changes:

1. **Delete `decorum.rb` entry point** — let Zeitwerk handle all loading
2. **Move `concerns/humanized_name.rb` to `decorum/humanized_name.rb`** — file path must match module name (`Decorum::HumanizedName`)
3. **Remove `require_relative "decorum/house"` load-order hack** — Zeitwerk handles constant resolution automatically
4. **Verify `app/lib/` is in autoload paths**: `config.autoload_paths << Rails.root.join("app/lib")` in `config/application.rb`
5. **Drop Ruby scenario subclasses** (`WelcomeHome.rb`) — scenarios are seeded from JSON files into the database

---

## Scaling Notes

- **Solid Cable** uses database polling (~0.1s interval). Works fine for turn-based games up to ~5K concurrent connections. Beyond that, switch to Redis-backed ActionCable.
- **Live cursor presence** (Nice to Have) generates high-frequency writes — requires Redis, not Solid Cable.
- **`house_state_after` snapshots**: ~48KB per game (60 moves × 800 bytes). At 1M games = ~50GB. Revisit snapshot frequency at scale.
- **Partitioning**: Consider for `game_moves` at 500K-1M games (time-based partitioning).

---

## Testing Strategy

### Test pyramid
- **Domain layer** (Minitest, existing ~243 tests): Run against `app/lib/decorum/`
- **Model tests** (~40): Validations, scopes, state machine transitions, callbacks
- **Service/Engine tests** (~60): Move validation, scoring, supply tracking, serialization round-trips
- **Request tests** (~30): Game CRUD, moves, leaderboard, solution checker
- **System tests** (~15, Capybara + Cuprite): Full game play-through, curtain screen, drag-and-drop
- **Job tests** (~10): Stale detection, difficulty analysis
- **JSONB round-trip tests**: Verify serialization/deserialization preserves state exactly
- **Concurrent access tests**: Verify `StaleObjectError` on double-submit, handled gracefully

---

## MVP Implementation Plan

### Phase 1: Foundation
1. `rails new decorum --database=postgresql` with Rails 8
2. Create database schema with CHECK constraints, indexes, cascades
3. Migrate existing library to `app/lib/decorum/` (fix Zeitwerk issues)
4. Implement `Game::StateSerializer` (bidirectional, based on ScenarioLoader)
5. Seed built-in scenarios from existing JSON files
6. Guest session infrastructure

### Phase 2: Game Engine
1. Implement AASM state machine on Game
2. Implement `Game::Engine` with action command pattern + registry
3. All 5 action types with full validation (including pass-only-when-fulfilled)
4. Object supply tracking
5. Round marker tracking (2P: reset only after first H2H; 3/4P: reset after every meeting)
6. Heart-to-Heart logic (sharing, visibility, skip-ahead proposal)
7. Fulfillment re-check after every move
8. Win/loss detection and scoring
9. Game::Event logging for all state transitions

### Phase 3: Game UI
1. Design SVG assets (rooms, objects, style/keyword icons)
2. Build game board view with Turbo 8 morphing
3. Implement Stimulus controllers (drag-and-drop, paint picker, turn flow)
4. Build condition display with inline keyword icons + glossary panel
5. Build curtain screen for local multiplayer (with Turbo cache disabled)
6. Responsive layout (mobile + tablet + desktop)

### Phase 4: Solution Checker & Leaderboards
1. Build solution checker UI (same board, free-form editing)
2. Implement per-condition breakdown (with grouped each_room condition display)
3. Build gameplay leaderboard view with Pagy pagination
4. Implement scoring + Scenario::Score on game completion
5. User accounts (Rails 8 auth) for leaderboard submission

### Phase 5: Testing
1. Migrate existing domain tests
2. Model + service + request + system + job tests
3. JSONB round-trip and concurrent access tests

---

## Round Tracking

The physical game uses a round marker on a numbered track. The reset behavior differs between 2P and 3/4P:

**2-player** (track 1-15, reset ONLY after first H2H):
- Marker 1→15: H2H #1. Heart consumed. Marker resets to 1.
- Marker 1→5: H2H #2. Heart consumed. Marker does NOT reset. Continues.
- Marker 5→10: H2H #3. Heart consumed. Marker does NOT reset.
- Marker 10→15: Game ends (0 hearts remaining). Total: 30 rounds.

**3/4-player** (track 1-5, reset after EVERY House Meeting):
- Marker 1→5: Meeting. Heart consumed. Reset to 1. Repeat × 5.
- After last meeting: marker 1→5. Game ends. Total: 30 rounds.

**Database:** `round_marker` (position on track) + `heart_to_hearts_held` (count) + `total_rounds_played` (cumulative).

**H2H trigger (2P):** First at marker=15. After reset: at marker=5 and marker=10.
**Meeting trigger (3/4P):** Always at marker=5.
**Game end (2P):** `heart_to_hearts_held == 3 AND round_marker > 15`.
**Game end (3/4P):** `hearts_remaining == 0 AND round_marker > 5`.

---

## Guest Ownership of Game Players

Guests need a way to be linked to their `game_player` records. Add a `guest_id` column to `game_players`:

```ruby
t.string :guest_id, limit: 36  # UUID from session cookie
t.index [:guest_id], where: "guest_id IS NOT NULL", name: "idx_game_players_guest"
```

When a guest creates an account, migrate their records: `GamePlayer.where(guest_id: current_guest_id).update_all(user_id: new_user.id, guest_id: nil)`.

---

## Game State Machine

AASM states and transitions:

```
States: waiting, in_progress, completed, abandoned

waiting → in_progress    (start — when all players joined, online mode only)
in_progress → completed  (finish — all players fulfilled OR out of rounds)
in_progress → abandoned  (abandon — stale game cleanup or player leaves)
```

Local mode games skip `waiting` and start directly in `in_progress`.

Add CHECK constraint to schema:
```ruby
t.check_constraint "state IN ('waiting', 'in_progress', 'completed', 'abandoned')"
```

---

## Object Supply Tracking

Computed dynamically from `house_state`, not stored separately. The supply for each object = 4 minus the count of that object currently in the house. Since the house state is always known, no separate tracking column is needed.

```ruby
# Game::Engine helper
def available_supply(house_state)
  placed = house_state.rooms.flat_map(&:objects).group_by { |o| [o.type, o.color, o.style] }
  ObjectSlot::COMBINATIONS.flat_map { |type, combos|
    combos.map { |c| { type:, **c, remaining: 4 - placed.fetch([type, c[:color], c[:style]], []).size } }
  }
end
```

---

## Ruby Condition Subclasses

The 6 Ruby condition subclasses (`KitchenNoObjects`, `LeftNoLamps`, etc.) are **not needed for the Rails app**. All scenarios use declarative JSON conditions via `ScenarioLoader`. The Ruby classes exist only for the original `WelcomeHome.setup` Ruby entry point.

**Decision:** Keep them in `app/lib/decorum/` for backwards compatibility with existing tests, but do not use them in the Rails app. All game conditions flow through `Conditions::Declarative`.

---

## Solution Checker vs Solver

The plan's "solution checker" feature is **not** the `Solver` (CSP backtracking). It's a UI where users manually configure a house and check conditions:

- Uses `Conditions::Declarative#fulfilled?` to evaluate each condition against the user's house configuration
- Shows per-condition pass/fail breakdown
- No search/solving involved — purely evaluation
- The existing `Scenario#win?` method delegates to this same fulfillment check

The `Solver` and `DifficultyAnalyzer` are used only for the Post-MVP difficulty analysis feature (run async via Solid Queue, results cached in `difficulty_score`/`difficulty_report`/`solution_count` columns on `scenarios`).

---

## `each_room` Condition Handling

`each_room` conditions (e.g., "each room must contain at least one object") are **stored unexpanded** in the database as a single condition definition. They are expanded at evaluation time using `Declarative#expand(house)`, which produces per-room sub-conditions with a shared `group` ID.

For the solution checker UI, expanded sub-conditions are displayed grouped together under the parent condition, showing per-room pass/fail status.

---

## Scenario Conditions → Game Player Conditions

When a game is created from a scenario:

1. Read `scenario.conditions` (JSONB containing all players' condition definitions, grouped by player index)
2. For each player, copy their condition definitions into `game_player.conditions`
3. Game player conditions are the source of truth during gameplay — the scenario's conditions are never consulted again

The scenario's `conditions` column stores the template; it is **not secret** (visible in scenario browsing). Game player conditions are secret during gameplay (scoped to the owning player).

---

## Resolved Decisions

1. **Object supply**: 4 copies of each of the 12 specific objects (48 tokens total, per PDF game setup).
2. **Guest play**: Session-based guest UUID. Account only for leaderboard.
3. **Leaderboard**: Gameplay-only. No solution checker leaderboard.
4. **Heart-to-Heart tracking**: Single source of truth via Game::Event.
5. **Locking**: Optimistic (`lock_version`). `last_activity_at` updated via raw SQL to avoid lock conflicts.
6. **Enums**: String-backed everywhere.
7. **State snapshots**: Keep on every move. Revisit at 1M+ games.
8. **Conditions storage**: JSONB (not has_many). Plain JSONB — no encryption needed.
9. **Sequence numbers**: Shared counter between moves and events for replay.
10. **Fulfillment**: Re-checked after every move, not just acting player's turn.
11. **Shared conditions**: Become visible to recipients after Heart-to-Heart.
12. **Invite codes**: 8 characters alphanumeric. Rate-limited join endpoint.
13. **Moderation**: Phase 4+ — report + admin review.
14. **Game replays**: Phase 4+ — shareable link.
15. **Difficulty calibration**: Future, with more data points.
16. **Guest ownership**: `guest_id` column on `game_players`. Migrated to `user_id` on account creation.
17. **Game states**: `waiting`, `in_progress`, `completed`, `abandoned`. Local mode skips `waiting`.
18. **Object supply**: Computed from house_state (4 minus placed count). No separate column.
19. **Ruby condition classes**: Kept in `app/lib/` for test compatibility, not used by Rails app.
20. **Solution checker**: Uses `Conditions::Declarative#fulfilled?`, not the `Solver`.
21. **`each_room` conditions**: Stored unexpanded, expanded at evaluation time via `Declarative#expand`.

---

## Verification

### MVP smoke test
1. Play as guest (no account)
2. Browse scenarios, pick Welcome Home
3. Start local 2-player game
4. Play full game (actions, comments, Heart-to-Heart with condition sharing)
5. Verify shared conditions visible to recipient after Heart-to-Heart
6. Complete game → prompted to create account for leaderboard
7. Create account → see score on leaderboard
8. Use solution checker → see per-condition breakdown
9. Run full test suite
