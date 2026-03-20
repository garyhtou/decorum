require "minitest/autorun"
require_relative "../decorum"

class SolverTest < Minitest::Test
  def test_solves_welcome_home
    scenario = Decorum::Scenarios::WelcomeHome.setup
    solver = Decorum::Solver.new(scenario)
    solution = solver.run

    assert solution, "Expected solver to find a solution"
    assert scenario.win?(using_house: solution), "Solution must satisfy all conditions"
  end

  def test_solution_has_correct_room_names
    scenario = Decorum::Scenarios::WelcomeHome.setup
    solution = Decorum::Solver.new(scenario).run

    assert_equal :bathroom, solution.top_left_room.name
    assert_equal :bedroom, solution.top_right_room.name
    assert_equal :living_room, solution.bottom_left_room.name
    assert_equal :kitchen, solution.bottom_right_room.name
  end

  def test_known_solution_is_valid
    scenario = Decorum::Scenarios::WelcomeHome.setup
    known = Decorum::Scenarios::WelcomeHome.solution

    assert scenario.win?(using_house: known), "Known solution should be valid"
  end

  def test_initial_state_is_not_a_solution
    scenario = Decorum::Scenarios::WelcomeHome.setup

    refute scenario.win?, "Initial state should not satisfy all conditions"
  end

  def test_returns_nil_for_unsolvable_scenario
    house = Decorum::House::TwoPlayer.new
    house.bathroom.paint_color = :red
    house.bedroom.paint_color = :red
    house.living_room.paint_color = :red
    house.kitchen.paint_color = :red

    # Contradictory: left must be blue AND left must be red
    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [
        Decorum::Conditions::LeftPaintedBlue.new
      ]),
      player_two: Decorum::Player.new(conditions: [
        LeftPaintedRed.new
      ])
    )

    solution = Decorum::Solver.new(scenario).run
    assert_nil solution, "Should return nil for unsolvable scenario"
  end

  def test_solves_single_condition
    house = Decorum::House::TwoPlayer.new
    house.bathroom.paint_color = :red
    house.bedroom.paint_color = :red
    house.living_room.paint_color = :red
    house.kitchen.paint_color = :red

    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [
        Decorum::Conditions::LeftPaintedBlue.new
      ])
    )

    solution = Decorum::Solver.new(scenario).run

    assert solution, "Expected solver to find a solution"
    assert_equal :blue, solution.top_left_room.paint_color
    assert_equal :blue, solution.bottom_left_room.paint_color
  end

  def test_solves_kitchen_no_objects
    house = Decorum::House::TwoPlayer.new
    house.bathroom.paint_color = :red
    house.bedroom.paint_color = :red
    house.living_room.paint_color = :red
    house.kitchen.tap do |room|
      room.paint_color = :red
      room.lamp.assign_attributes(color: :blue, style: :modern)
    end

    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [
        Decorum::Conditions::KitchenNoObjects.new
      ])
    )

    solution = Decorum::Solver.new(scenario).run

    assert solution, "Expected solver to find a solution"
    assert_empty solution.bottom_right_room.objects
  end

  def test_solution_is_independent_copy
    scenario = Decorum::Scenarios::WelcomeHome.setup
    solution = Decorum::Solver.new(scenario).run

    # Mutating the solution should not affect a second solve
    solution.top_left_room.paint_color = :yellow
    solution2 = Decorum::Solver.new(scenario).run

    assert scenario.win?(using_house: solution2)
  end

  def test_room_detection_for_single_room_condition
    house = Decorum::House::TwoPlayer.new
    house.bathroom.paint_color = :red
    house.bedroom.paint_color = :red
    house.living_room.paint_color = :red
    house.kitchen.paint_color = :red

    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [
        Decorum::Conditions::KitchenNoObjects.new
      ])
    )

    space = Decorum::SearchSpace.new(scenario)
    kitchen_entry = space.condition_entries.find { |e| e[:condition].is_a?(Decorum::Conditions::KitchenNoObjects) }

    assert_equal [:bottom_right_room], kitchen_entry[:required_rooms]
  end

  def test_room_detection_for_two_room_condition
    scenario = Decorum::Scenarios::WelcomeHome.setup
    space = Decorum::SearchSpace.new(scenario)

    entry = space.condition_entries.find { |e| e[:condition].is_a?(Decorum::Conditions::LeftPaintedBlue) }

    assert_includes entry[:required_rooms], :top_left_room
    assert_includes entry[:required_rooms], :bottom_left_room
    assert_equal 2, entry[:required_rooms].size
  end

  def test_room_detection_for_house_wide_condition
    scenario = Decorum::Scenarios::WelcomeHome.setup
    space = Decorum::SearchSpace.new(scenario)

    entry = space.condition_entries.find { |e| e[:condition].is_a?(Decorum::Conditions::MaxOneAntique) }

    assert_equal 4, entry[:required_rooms].size
  end

  def test_solves_scenario_with_no_conditions
    house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each { |r| house.send(r).paint_color = :red }

    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [])
    )

    solution = Decorum::Solver.new(scenario).run

    assert solution, "Should find a solution when there are no conditions"
  end

  def test_solves_with_single_player
    house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each { |r| house.send(r).paint_color = :red }

    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [
        Decorum::Conditions::LeftPaintedBlue.new,
        Decorum::Conditions::KitchenNoObjects.new,
      ])
    )

    solution = Decorum::Solver.new(scenario).run

    assert solution
    assert_equal :blue, solution.top_left_room.paint_color
    assert_equal :blue, solution.bottom_left_room.paint_color
    assert_empty solution.bottom_right_room.objects
  end
end

# A condition that contradicts LeftPaintedBlue (for unsolvable test)
class LeftPaintedRed < Decorum::Condition
  def fulfilled?(player:, house:)
    house.top_left_room.paint_color == :red && house.bottom_left_room.paint_color == :red
  end
end
