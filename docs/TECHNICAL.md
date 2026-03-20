# Technical Implementation

> This is a living document. It should be kept up to date as the codebase evolves.

## Overview

This codebase models the Decorum board game, with a focus on validating house configurations against player conditions and solving scenarios automatically. Written in Ruby using ActiveModel for model validation and attributes.

## Project Structure

```
decorum.rb                    # Entry point, loads all files, defines COLORS
decorum/
  house.rb                    # House base class (4 room positions, POSITION_GROUPS)
  house/
    two_player.rb             # 2P layout: bathroom, bedroom, living room, kitchen
    four_player.rb            # 3-4P layout: bedroom_a, bedroom_b, living room, kitchen
  room.rb                     # Room with paint color + 3 object slots
  object_slot.rb              # Object slot (type + color + style, or empty)
  player.rb                   # Player with conditions list
  condition.rb                # Abstract base condition class
  conditions/                 # Concrete condition implementations
    declarative.rb            # Data-driven condition evaluated from a definition hash
    kitchen_no_objects.rb
    left_no_lamps.rb
    left_painted_blue.rb
    max_one_antique.rb
    min_one_antique_yellow_lamp.rb
    downstairs_min_two_objects.rb
  scenario.rb                 # Scenario (house + players), win checking
  scenario_loader.rb          # Loads scenarios from JSON
  scenarios/
    welcome_home.rb           # Scenario 1 (Ruby class with setup + known solution)
    welcome_home.json         # Scenario 1 (JSON format)
  search_space.rb             # Shared search infrastructure (domains, probing, filtering)
  solver.rb                   # CSP backtracking solver (finds first solution)
  difficulty_analyzer.rb      # Exhaustive search + difficulty metrics
  display.rb                  # Console rendering (ASCII art templates)
  concerns/
    humanized_name.rb         # Mixin for human-readable attribute names
docs/
  RULES.md                    # Complete game rules from the rulebook
  TECHNICAL.md                # This file
test/
  solver_test.rb
  house_test.rb
  room_test.rb
  object_slot_test.rb
  scenario_test.rb
  scenario_loader_test.rb
  conditions_test.rb
  declarative_condition_test.rb
  difficulty_analyzer_test.rb
  display_test.rb
bin/
  console                     # Interactive debugger
  test                        # Runs full test suite
```

## Core Model

### House

`Decorum::House` holds 4 room positions as a 2x2 grid:

```
top_left_room    | top_right_room
-----------------+-----------------
bottom_left_room | bottom_right_room
```

Subclasses define `ROOM_NAMES` mapping game-specific names to positions, and derive `alias_attribute` calls from it:
- `House::TwoPlayer`: bathroom (TL), bedroom (TR), living_room (BL), kitchen (BR)
- `House::FourPlayer`: bedroom_a (TL), bedroom_b (TR), living_room (BL), kitchen (BR)

`House::POSITION_GROUPS` defines spatial scopes used by conditions and the solver:
- `upstairs` → top_left + top_right
- `downstairs` → bottom_left + bottom_right
- `left_side` → top_left + bottom_left
- `right_side` → top_right + bottom_right

Key methods:
- `rooms` — Returns non-nil rooms (compacts nil positions)
- `objects` — All filled object slots across all rooms
- `clear!` — Sets all room positions to nil
- `deep_dup` — Creates a fully independent copy

### Room

`Decorum::Room` has:
- `name` — One of `:bedroom`, `:bathroom`, `:kitchen`, `:living_room`, `:bedroom_a`, `:bedroom_b`
- `paint_color` — One of `:red`, `:blue`, `:green`, `:yellow`
- `lamp`, `curio`, `wall_hanging` — Three `ObjectSlot` instances
- `object_order` — Display order for rendering (does not affect game logic)

Key methods:
- `objects` — Returns only filled slots
- `object_slots` — Returns all 3 slots in display order

`Room::OBJECTS` references `ObjectSlot::TYPES` as the canonical list of slot types.

### ObjectSlot

`Decorum::ObjectSlot` represents a single object slot in a room:
- `type` — One of `:lamp`, `:curio`, `:wall_hanging` (defined in `TYPES`)
- `color` — One of `:red`, `:blue`, `:green`, `:yellow` (nil when empty)
- `style` — One of `:modern`, `:antique`, `:retro`, `:unusual` (defined in `STYLES`, nil when empty)

Each type has exactly 4 valid color/style combinations (defined in `COMBINATIONS`), plus the empty state. There are 5 possible states per slot and 12 unique filled objects across all types.

### Scenario

`Decorum::Scenario` holds:
- `house` — The initial house configuration
- `player_one` through `player_four` — Players (nil for unused slots)

Key method: `win?(using_house:)` — Returns true if all players' conditions are fulfilled for the given house state.

### Player

`Decorum::Player` holds an array of `conditions` and delegates fulfillment checking to them via `fulfilled?(house:)`.

### Condition

`Decorum::Condition` is the abstract base class. Subclasses implement `fulfilled?(player:, house:)` which returns true/false by inspecting the house state.

There are two ways to define conditions:

1. **Ruby subclass** — Write a class in `decorum/conditions/` inheriting from `Condition`
2. **Declarative (data-driven)** — Use `Conditions::Declarative` with a definition hash (see below)

Conditions access the house through its room position accessors (e.g., `house.top_left_room.paint_color`). They do not modify state.

## Declarative Conditions

`Decorum::Conditions::Declarative` evaluates conditions from a definition hash, enabling conditions to be defined as data (JSON) rather than code.

### Evaluation pipeline

```
1. Resolve scope    → set of rooms
2. Resolve subject  → set of values (paint colors, objects, slots)
3. Apply filter     → narrow by attributes (color, style, type)
4. Evaluate assertion → true/false
```

### Scopes

| Scope | Rooms |
|-------|-------|
| `house` | All 4 rooms |
| `upstairs` / `downstairs` | Top/bottom row (via `House::POSITION_GROUPS`) |
| `left_side` / `right_side` | Left/right column (via `House::POSITION_GROUPS`) |
| Room name (e.g., `kitchen`) | Single room (via subclass `ROOM_NAMES`) |

### Subjects

| Subject | Returns |
|---------|---------|
| `paint_color` | Array of room paint color symbols |
| `objects` | All filled ObjectSlot instances |
| `lamps` / `curios` / `wall_hangings` | Specific slot type from each room |
| `features` | Paint colors + object colors combined |
| `empty_slots` | Unfilled ObjectSlot instances |

### Assertions

| Assertion | Meaning |
|-----------|---------|
| `{ "equals": "blue" }` | All values equal the given value |
| `{ "not_equals": "blue" }` | No values equal the given value |
| `{ "includes": "blue" }` | At least one value matches |
| `{ "excludes": "blue" }` | No values match |
| `{ "count": { "min": N } }` | Count >= N |
| `{ "count": { "max": N } }` | Count <= N |
| `{ "count": { "equals": N } }` | Count == N |

### Filter

Optional `filter` narrows object-type subjects by attribute matches before the assertion:
```json
{ "filter": { "style": "antique" } }
{ "filter": { "type": "lamp", "color": "yellow", "style": "antique" } }
```

## JSON Scenario Format

Entire scenarios can be defined as JSON via `ScenarioLoader`:

```json
{
  "name": "Welcome Home",
  "house_type": "two_player",
  "initial_state": {
    "bathroom": {
      "paint_color": "blue",
      "curio": { "color": "blue", "style": "antique" }
    },
    "bedroom": { "paint_color": "green" },
    "living_room": { "paint_color": "yellow" },
    "kitchen": { "paint_color": "red" }
  },
  "players": [
    {
      "conditions": [
        {
          "scope": "kitchen",
          "subject": "objects",
          "assertion": { "count": { "max": 0 } }
        }
      ]
    }
  ]
}
```

Load with:
```ruby
scenario = Decorum::ScenarioLoader.load_file("decorum/scenarios/welcome_home.json")
```

See `decorum/scenarios/welcome_home.json` for a complete example.

## SearchSpace

`Decorum::SearchSpace` encapsulates all search preparation shared by the Solver and DifficultyAnalyzer:

1. **Object pool** — 15 shared `ObjectSlot` instances (3 types x 5 states)
2. **Room domains** — 500 `Room` objects per position (4 colors x 5^3 object combos)
3. **Required room detection** — Auto-detects which rooms each condition accesses via singleton method probing. Two probes with different house states handle short-circuit evaluation. A `rescue NoMethodError` safety net handles edge cases.
4. **Unary filtering** — Conditions referencing a single room pre-filter that room's domain
5. **Room ordering** — Most constrained rooms first (smallest domain after filtering)
6. **Condition triggers** — Groups conditions by the backtracking depth at which they become checkable

Public accessors: `domains`, `room_order`, `conditions_by_trigger`, `condition_entries`, `unfiltered_domain_sizes`, `safe_check`.

## Solver

`Decorum::Solver` finds a house configuration that satisfies all conditions using **CSP backtracking** over the `SearchSpace`.

### Why Not BFS?

The state space is ~62.5 billion configurations (4 rooms x 500 states each). BFS over individual changes is infeasible.

### Performance

For the WelcomeHome scenario:
- Unary filtering: `KitchenNoObjects` reduces kitchen domain from 500 to 4
- Binary pruning: `LeftPaintedBlue` + `LeftNoLamps` reduce left rooms to ~25 states each
- Solve time: ~40ms

## DifficultyAnalyzer

`Decorum::DifficultyAnalyzer` measures how hard a scenario is for human players by performing an exhaustive search over the `SearchSpace`.

### Metrics

| Metric | Description |
|--------|-------------|
| `solution_count` | Total valid configurations (capped, default 10K) |
| `min_moves` / `avg_moves` / `max_moves` | Changes needed from initial state to each solution |
| `constraint_tightness` | Domain sizes after unary filtering per room (ratio of filtered/total) |
| `condition_count` | Total and per-player condition counts |
| `condition_locality` | Conditions categorized as single-room, two-room, or house-wide |
| `conflict_density` | How many conditions reference each room position |
| `difficulty_score` | Composite 0.0–1.0 (weighted: solution scarcity, min moves, condition count, house-wide ratio, conflict density) |

### Usage

```ruby
report = Decorum::DifficultyAnalyzer.new(scenario, solution_cap: 50_000).analyze
pp report
```

## Display

`Decorum::Display` renders ASCII art for the console using templates for each object type:

```
 /‾\       /◠\        ┌-◠-┐
└   ┘     |   |       │   │
 ─┴─      └───┘       └───┘
Lamp      Curio    Wall Hanging
```

Object colors are rendered using the `rainbow` gem for ANSI terminal colors. The first letter of the style is shown inside the template (M/A/R/U). Empty slots show a blank space.

## Dependencies

- `activemodel` — Model validation and attributes
- `activesupport` — Core extensions (`deep_dup`, `humanize`, etc.)
- `rainbow` — ANSI color output for console rendering

## Adding a New Condition

### Option 1: Ruby class

1. Create a file in `decorum/conditions/` inheriting from `Decorum::Condition`
2. Implement `fulfilled?(player:, house:)` returning true/false
3. The SearchSpace will automatically detect which rooms it accesses

```ruby
module Decorum
  module Conditions
    class MyCondition < ::Decorum::Condition
      def fulfilled?(player:, house:)
        # Inspect house state and return true/false
      end
    end
  end
end
```

### Option 2: Declarative (JSON)

Define the condition as data — no Ruby code needed:

```json
{
  "scope": "house",
  "subject": "objects",
  "filter": { "style": "antique" },
  "assertion": { "count": { "max": 1 } }
}
```

## Adding a New Scenario

### Option 1: Ruby class

```ruby
module Decorum
  module Scenarios
    class MyScenario < Scenario
      def self.setup
        house = House::TwoPlayer.new
        # Configure rooms...
        new(
          house: house,
          player_one: Player.new(conditions: [...]),
          player_two: Player.new(conditions: [...]),
        )
      end
    end
  end
end
```

### Option 2: JSON file

Create a `.json` file and load it with `ScenarioLoader.load_file`. See `decorum/scenarios/welcome_home.json` for the full format.

## Running

```ruby
require_relative "decorum"

# Load scenario (Ruby)
scenario = Decorum::Scenarios::WelcomeHome.setup

# Load scenario (JSON)
scenario = Decorum::ScenarioLoader.load_file("decorum/scenarios/welcome_home.json")

# Solve
solution = Decorum::Solver.new(scenario).run
puts solution
puts scenario.win?(using_house: solution)  # => true

# Analyze difficulty
report = Decorum::DifficultyAnalyzer.new(scenario).analyze
pp report
```

## Testing

```sh
bin/test
```
