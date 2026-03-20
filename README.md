# Décorum

> A game of passive aggressive cohabitation.

- 🎲 Game Designer ([Floodgate Games](https://floodgate.games/products/decorum))
- 📋 Rule Book
  ([PDF](https://media.floodgate.games/rule-books/Decorum-Rule-Book.pdf))

Decorum is a board game. The creators describe it as a game of passive aggressive cohabitation.

With limited communication, you cooperate with roommates to decorate your house.
But there's a catch. Each person has a set of secret conditions that must be met.
The goal is to decorate the house in a manner that fulfills everyone's conditions
before the time runs out!

![image](https://m.media-amazon.com/images/S/aplus-media-library-service-media/fb6f183d-6079-4cfa-b612-bb59de28180a.__CR0,0,300,300_PT0_SX300_V1___.png)

~~Theoretically~~, every scenario (game level) has a solution. But from personal
experience, we sometimes rip out our hair trying to find said solution.

**So... what is this repo?**

A scenario solver, difficulty analyzer, and toolkit for the Decorum board game.

### Features

- [x] Solution checker (validates fulfillment of scenarios given a proposed solution)
- [x] Scenario solver (given a scenario, returns a valid solution)
- [x] Difficulty analyzer (measures how hard a scenario is for human players)
- [x] JSON scenario format (define scenarios as data, no code needed)
- [ ] TODO: Scenario generator

## Getting Started

```sh
bundle install
bin/console
```

### Load a scenario

```ruby
# From Ruby
scenario = Decorum::Scenarios::WelcomeHome.setup

# From JSON
scenario = Decorum::ScenarioLoader.load_file("decorum/scenarios/welcome_home.json")

puts scenario.house
```

![image](https://github.com/user-attachments/assets/92440c2d-b7c4-4173-84b9-04a73fa4efe9)

### Solve it

```ruby
solution = Decorum::Solver.new(scenario).run
puts solution
puts scenario.win?(using_house: solution)  # => true
```

### Analyze difficulty

```ruby
report = Decorum::DifficultyAnalyzer.new(scenario).analyze
pp report
# => { solution_count: 36864, min_moves: 7, difficulty_score: 0.515, ... }
```

## Creating a New Scenario

### Option 1: JSON (recommended)

Create a `.json` file in `decorum/scenarios/`:

```json
{
  "name": "My Scenario",
  "house_type": "two_player",
  "initial_state": {
    "bathroom": {
      "paint_color": "blue",
      "lamp": { "color": "blue", "style": "modern" }
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
        },
        {
          "scope": "left_side",
          "subject": "paint_color",
          "assertion": { "equals": "blue" }
        }
      ]
    },
    {
      "conditions": [
        {
          "scope": "house",
          "subject": "objects",
          "filter": { "style": "antique" },
          "assertion": { "count": { "max": 1 } }
        }
      ]
    }
  ]
}
```

Load it with:
```ruby
scenario = Decorum::ScenarioLoader.load_file("decorum/scenarios/my_scenario.json")
```

See [`docs/TECHNICAL.md`](docs/TECHNICAL.md) for the full condition format reference (scopes, subjects, filters, assertions).

### Option 2: Ruby class

```ruby
module Decorum
  module Scenarios
    class MyScenario < Scenario
      def self.setup
        house = House::TwoPlayer.new
        house.bathroom.paint_color = :blue
        house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
        # ... configure other rooms

        new(
          house: house,
          player_one: Player.new(conditions: [
            Conditions::Declarative.new(definition: {
              scope: "kitchen", subject: "objects",
              assertion: { count: { max: 0 } }
            })
          ]),
          player_two: Player.new(conditions: [
            Conditions::KitchenNoObjects.new  # or use a Ruby condition class
          ]),
        )
      end
    end
  end
end
```

## Testing

```sh
bin/test
```

## Legend

```
 /‾\       /◠\        ┌-◠-┐
└   ┘     |   |       │   │
 ─┴─      └───┘       └───┘
Lamp      Curio    Wall Hanging

M = Modern
A = Antique
R = Retro
U = Unusual

◌ = Empty slot (an object slot on the house board with nothing in it)

Color of text corresponds to the color of the object/wall paint
```

## Docs

- [`docs/RULES.md`](docs/RULES.md) — Complete game rules
- [`docs/TECHNICAL.md`](docs/TECHNICAL.md) — Technical implementation details
