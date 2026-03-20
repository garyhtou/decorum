require "minitest/autorun"
require_relative "../decorum"

class ScenarioTest < Minitest::Test
  def test_welcome_home_setup
    scenario = Decorum::Scenarios::WelcomeHome.setup

    assert_equal 2, scenario.num_players
    assert_equal 3, scenario.player_one.conditions.size
    assert_equal 3, scenario.player_two.conditions.size
    assert_kind_of Decorum::House::TwoPlayer, scenario.house
  end

  def test_welcome_home_initial_state_does_not_win
    scenario = Decorum::Scenarios::WelcomeHome.setup

    refute scenario.win?
  end

  def test_welcome_home_known_solution_wins
    scenario = Decorum::Scenarios::WelcomeHome.setup
    solution = Decorum::Scenarios::WelcomeHome.solution

    assert scenario.win?(using_house: solution)
  end

  def test_win_checks_all_players
    house = Decorum::House::TwoPlayer.new
    house.bathroom.paint_color = :blue
    house.living_room.paint_color = :blue

    # Player one satisfied, player two not
    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [
        Decorum::Conditions::LeftPaintedBlue.new
      ]),
      player_two: Decorum::Player.new(conditions: [
        Decorum::Conditions::KitchenNoObjects.new,
        Decorum::Conditions::MinOneAntiqueYellowLamp.new
      ])
    )

    refute scenario.win?, "Should not win when player_two has unfulfilled conditions"
  end

  def test_players_excludes_nil
    scenario = Decorum::Scenario.new(
      house: Decorum::House::TwoPlayer.new,
      player_one: Decorum::Player.new(conditions: [])
    )

    assert_equal 1, scenario.players.size
  end

  def test_conditions_returns_player_to_conditions_map
    scenario = Decorum::Scenarios::WelcomeHome.setup
    conds = scenario.conditions

    assert_equal 2, conds.size
    conds.each do |player, conditions|
      assert_kind_of Decorum::Player, player
      assert_equal 3, conditions.size
    end
  end

  def test_deep_dup_isolates_house
    scenario = Decorum::Scenarios::WelcomeHome.setup
    copy = scenario.deep_dup

    copy.house.bathroom.paint_color = :yellow

    assert_equal :blue, scenario.house.bathroom.paint_color
  end

  def test_win_with_no_conditions
    scenario = Decorum::Scenario.new(
      house: Decorum::House::TwoPlayer.new,
      player_one: Decorum::Player.new(conditions: [])
    )

    assert scenario.win?, "No conditions means always fulfilled"
  end

  def test_num_players_with_four
    scenario = Decorum::Scenario.new(
      house: Decorum::House::FourPlayer.new,
      player_one: Decorum::Player.new(conditions: []),
      player_two: Decorum::Player.new(conditions: []),
      player_three: Decorum::Player.new(conditions: []),
      player_four: Decorum::Player.new(conditions: []),
    )

    assert_equal 4, scenario.num_players
  end

  def test_setup_raises_on_base_class
    assert_raises(NotImplementedError) { Decorum::Scenario.setup }
  end
end
