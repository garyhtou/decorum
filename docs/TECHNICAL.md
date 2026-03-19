# Technical Implementation

## Overview

This codebase models the Decorum board game, with a focus on validating house configurations against player conditions and solving scenarios automatically. Written in Ruby using ActiveModel for model validation and attributes.

## Project Structure

```
decorum.rb                    # Entry point, loads all files, defines COLORS
decorum/
  house.rb                    # House base class (4 room positions)
  house/
    two_player.rb             # 2P layout: bathroom, bedroom, living room, kitchen
    four_player.rb            # 3-4P layout: bedroom_a, bedroom_b, living room, kitchen
  room.rb                     # Room with paint color + 3 object slots
  object_slot.rb              # Object slot (type + color + style, or empty)
  player.rb                   # Player with conditions list
  condition.rb                # Abstract base condition class
  conditions/                 # Concrete condition implementations
    kitchen_no_objects.rb
    left_no_lamps.rb
    left_painted_blue.rb
    max_one_antique.rb
    min_one_antique_yellow_lamp.rb
    downstairs_min_two_objects.rb
  scenario.rb                 # Scenario (house + players), win checking
  scenarios/
    welcome_home.rb           # Scenario 1 with setup and known solution
  solver.rb                   # CSP backtracking solver
  display.rb                  # Console rendering (ASCII art templates)
  concerns/
    humanized_name.rb         # Mixin for human-readable attribute names
test/
  solver_test.rb
  house_test.rb
  room_test.rb
  object_slot_test.rb
  scenario_test.rb
  conditions_test.rb
  display_test.rb
```

## Core Model

### House

`Decorum::House` holds 4 room positions as a 2x2 grid:

```
top_left_room    | top_right_room
-----------------+-----------------
bottom_left_room | bottom_right_room
```

Subclasses alias these positions to game-specific room names:
- `House::TwoPlayer`: bathroom (TL), bedroom (TR), living_room (BL), kitchen (BR)
- `House::FourPlayer`: bedroom_a (TL), bedroom_b (TR), living_room (BL), kitchen (BR)

Key methods:
- `rooms` - Returns non-nil rooms (compacts nil positions)
- `objects` - All filled object slots across all rooms
- `clear!` - Sets all room positions to nil
- `deep_dup` - Creates a fully independent copy

### Room

`Decorum::Room` has:
- `name` - One of `:bedroom`, `:bathroom`, `:kitchen`, `:living_room`
- `paint_color` - One of `:red`, `:blue`, `:green`, `:yellow`
- `lamp`, `curio`, `wall_hanging` - Three `ObjectSlot` instances
- `object_order` - Display order for rendering (does not affect game logic)

Key methods:
- `objects` - Returns only filled slots
- `object_slots` - Returns all 3 slots in display order

### ObjectSlot

`Decorum::ObjectSlot` represents a single object slot in a room:
- `type` - One of `:lamp`, `:curio`, `:wall_hanging`
- `color` - One of `:red`, `:blue`, `:green`, `:yellow` (nil when empty)
- `style` - One of `:modern`, `:antique`, `:retro`, `:unusual` (nil when empty)

Each type has exactly 4 valid color/style combinations (defined in `COMBINATIONS`), plus the empty state. There are 5 possible states per slot and 12 unique filled objects across all types.

### Scenario

`Decorum::Scenario` holds:
- `house` - The initial house configuration
- `player_one` through `player_four` - Players (nil for unused slots)

Key method: `win?(using_house:)` - Returns true if all players' conditions are fulfilled for the given house state.

### Player

`Decorum::Player` holds an array of `conditions` and delegates fulfillment checking to them via `fulfilled?(house:)`.

### Condition

`Decorum::Condition` is the abstract base class. Subclasses implement `fulfilled?(player:, house:)` which returns true/false by inspecting the house state.

Conditions access the house through its room position accessors (e.g., `house.top_left_room.paint_color`). They do not modify state.

## Solver

`Decorum::Solver` finds a house configuration that satisfies all conditions using **Constraint Satisfaction Problem (CSP) backtracking**.

### Why Not BFS?

The state space is ~62.5 billion configurations (4 rooms x 500 states each). BFS over individual changes is infeasible.

### Algorithm

1. **Pre-compute object pool**: 15 shared `ObjectSlot` instances (3 types x 5 states)
2. **Pre-compute room domains**: 500 `Room` objects per position (4 colors x 5^3 object combos)
3. **Auto-detect required rooms**: For each condition, probe which room accessors it calls using singleton methods on a test house. This determines at which backtracking depth each condition can be evaluated.
4. **Unary filtering**: Conditions that reference a single room pre-filter that room's domain (e.g., `KitchenNoObjects` reduces kitchen from 500 to 4 states)
5. **Room ordering**: Most constrained rooms first (smallest domain after filtering)
6. **Backtracking**: Assign room states depth-first, checking triggered conditions at each level. Final depth verifies all conditions via `scenario.win?`.

### Required Room Detection

The solver automatically detects which rooms each condition accesses by running the condition against a probe house with tracking singleton methods. Two probes with different house states handle short-circuit evaluation in conditions (e.g., `a && b` may skip `b` if `a` is false). A `rescue NoMethodError` safety net handles any remaining edge cases.

### Performance

For the WelcomeHome scenario:
- Unary filtering: `KitchenNoObjects` reduces kitchen domain from 500 to 4
- Binary pruning: `LeftPaintedBlue` + `LeftNoLamps` reduce left rooms to ~25 states each
- Solve time: ~40ms

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

- `activemodel` - Model validation and attributes
- `activesupport` - Core extensions (`deep_dup`, `humanize`, etc.)
- `rainbow` - ANSI color output for console rendering

## Adding a New Condition

1. Create a file in `decorum/conditions/` with a class inheriting from `Decorum::Condition`
2. Implement `fulfilled?(player:, house:)` returning true/false
3. The solver will automatically detect which rooms it accesses

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

## Adding a New Scenario

1. Create a file in `decorum/scenarios/` with a class inheriting from `Decorum::Scenario`
2. Implement `self.setup` returning a configured scenario instance
3. Optionally implement `self.solution` with a known valid house configuration

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

## Running

```ruby
# Load
require_relative "decorum"

# Check a scenario
scenario = Decorum::Scenarios::WelcomeHome.setup
puts scenario.house

# Solve it
solver = Decorum::Solver.new(scenario)
solution = solver.run
puts solution
puts scenario.win?(using_house: solution)  # => true
```

## Testing

```sh
bundle exec ruby -e 'Dir.glob("test/*_test.rb") { |f| require_relative f }'
```
