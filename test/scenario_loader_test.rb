require "minitest/autorun"
require_relative "../decorum"

class ScenarioLoaderTest < Minitest::Test
  JSON_PATH = File.join(__dir__, "../decorum/scenarios/welcome_home.json")

  def test_loads_json_file
    scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)

    assert_kind_of Decorum::Scenario, scenario
    assert_kind_of Decorum::House::TwoPlayer, scenario.house
  end

  def test_correct_player_count
    scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)

    assert_equal 2, scenario.num_players
  end

  def test_correct_condition_count
    scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)

    assert_equal 3, scenario.player_one.conditions.size
    assert_equal 3, scenario.player_two.conditions.size
  end

  def test_conditions_are_declarative
    scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)

    scenario.players.each do |player|
      player.conditions.each do |cond|
        assert_kind_of Decorum::Conditions::Declarative, cond
      end
    end
  end

  def test_initial_house_state
    scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)
    house = scenario.house

    assert_equal :blue, house.top_left_room.paint_color   # bathroom
    assert_equal :green, house.top_right_room.paint_color  # bedroom
    assert_equal :yellow, house.bottom_left_room.paint_color # living room
    assert_equal :red, house.bottom_right_room.paint_color   # kitchen
  end

  def test_initial_objects
    scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)
    house = scenario.house

    # Bathroom curio
    assert_equal :blue, house.top_left_room.curio.color
    assert_equal :antique, house.top_left_room.curio.style

    # Bedroom lamp
    assert_equal :green, house.top_right_room.lamp.color
    assert_equal :unusual, house.top_right_room.lamp.style

    # Kitchen wall hanging
    assert_equal :yellow, house.bottom_right_room.wall_hanging.color
    assert_equal :unusual, house.bottom_right_room.wall_hanging.style
  end

  def test_empty_slots_remain_empty
    scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)

    assert scenario.house.top_left_room.lamp.empty?
    assert scenario.house.top_right_room.curio.empty?
  end

  def test_initial_state_does_not_win
    scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)

    refute scenario.win?
  end

  def test_known_solution_wins
    scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)
    known_solution = Decorum::Scenarios::WelcomeHome.solution

    assert scenario.win?(using_house: known_solution)
  end

  def test_solver_finds_valid_solution
    scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)
    solution = Decorum::Solver.new(scenario).run

    assert solution, "Solver should find a solution"
    assert scenario.win?(using_house: solution)
  end

  def test_json_solution_also_wins_ruby_scenario
    json_scenario = Decorum::ScenarioLoader.load_file(JSON_PATH)
    ruby_scenario = Decorum::Scenarios::WelcomeHome.setup

    solution = Decorum::Solver.new(json_scenario).run

    assert ruby_scenario.win?(using_house: solution),
      "Solution from JSON scenario should also satisfy Ruby scenario"
  end

  def test_load_from_string
    json = File.read(JSON_PATH)
    scenario = Decorum::ScenarioLoader.load(json)

    assert_equal 2, scenario.num_players
    assert scenario.win?(using_house: Decorum::Scenarios::WelcomeHome.solution)
  end
end
