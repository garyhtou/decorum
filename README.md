# Décorum

> A game of passive aggressive cohabitation.

- 🎲 Game Designer ([Floodgate Games](https://floodgate.games/products/decorum))
- 📋 Rule Book
  ([PDF](https://media.floodgate.games/rule-books/Decorum-Rule-Book.pdf))

Decorum is a board game. The creators describe it as a game of passive aggressive cohabitation.

With limited communication, you cooperate with roommates to decorate your house.
But there's a catch. Each person as a set of secret conditions that must be met.
The goal is to decorate the house in a manner that fulfill everyone's conditions
before the time runs out!

![image](https://m.media-amazon.com/images/S/aplus-media-library-service-media/fb6f183d-6079-4cfa-b612-bb59de28180a.__CR0,0,300,300_PT0_SX300_V1___.png)

~~Theoretically~~, every scenario (game level) has a solution. But from personal
experience, we sometimes rip out our hair trying to find said solution.

**So... what is this repo?**

I'm not too sure 🤷‍♂️. It'll likely be a scenario solver but could turn into
more in the future:
- Scenario solver
- Scenario generator
- Online game

### Current Features

- [x] Solution checker (Validates fulfillment of scenarios)
- [ ] TODO: Scenario solver (solves a given scenario)

## Getting Started

```ruby
puts Decorum::Scenarios::WelcomeHome.setup.house
```
![image](https://github.com/user-attachments/assets/92440c2d-b7c4-4173-84b9-04a73fa4efe9)

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