require "minitest/autorun"
require_relative "../decorum"

class DifficultyAnalyzerTest < Minitest::Test
  def setup
    @scenario = Decorum::Scenarios::WelcomeHome.setup
    @analyzer = Decorum::DifficultyAnalyzer.new(@scenario)
    @report = @analyzer.analyze
  end

  def test_finds_solutions
    assert @report[:solution_count] > 0, "Expected at least one solution"
  end

  def test_move_distances_are_consistent
    assert @report[:min_moves] <= @report[:avg_moves]
    assert @report[:avg_moves] <= @report[:max_moves]
  end

  def test_min_moves_is_positive
    assert @report[:min_moves] > 0, "Initial state is not a solution, so min_moves > 0"
  end

  def test_max_moves_within_bounds
    assert @report[:max_moves] <= 16, "Max possible distance is 16 (4 rooms x 4 features)"
  end

  def test_constraint_tightness_ratios
    @report[:constraint_tightness].each do |position, data|
      assert_includes 0.0..1.0, data[:ratio],
        "Expected ratio for #{position} to be 0-1, got #{data[:ratio]}"
      assert data[:filtered] <= data[:total]
    end
  end

  def test_kitchen_is_most_constrained
    kitchen = @report[:constraint_tightness][:bottom_right_room]

    assert kitchen[:filtered] <= 4,
      "KitchenNoObjects should reduce kitchen to <= 4 states"
  end

  def test_condition_count
    assert_equal 6, @report[:condition_count][:total]
    assert_equal [3, 3], @report[:condition_count][:per_player]
  end

  def test_condition_locality
    locality = @report[:condition_locality]

    assert locality[:single_room] >= 1, "KitchenNoObjects is single-room"
    assert_equal 6, locality.values.sum, "All 6 conditions should be categorized"
  end

  def test_conflict_density_covers_all_rooms
    density = @report[:conflict_density]

    assert_equal 4, density.size, "Should have density for all 4 rooms"
    density.each do |pos, count|
      assert count >= 0, "Density for #{pos} should be non-negative"
    end
  end

  def test_difficulty_score_is_normalized
    assert_includes 0.0..1.0, @report[:difficulty_score],
      "Difficulty score should be 0.0-1.0, got #{@report[:difficulty_score]}"
  end

  def test_unsolvable_scenario_has_max_difficulty
    house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each { |r| house.send(r).paint_color = :red }

    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [
        Decorum::Conditions::LeftPaintedBlue.new
      ]),
      player_two: Decorum::Player.new(conditions: [
        LeftPaintedRed.new
      ])
    )

    report = Decorum::DifficultyAnalyzer.new(scenario).analyze

    assert_equal 0, report[:solution_count]
    assert_equal 1.0, report[:difficulty_score]
  end

  def test_solution_cap_limits_search
    analyzer = Decorum::DifficultyAnalyzer.new(@scenario, solution_cap: 2)
    report = analyzer.analyze

    assert report[:solution_count] <= 2
    assert report[:solution_count_capped]
  end

  def test_trivial_scenario_has_low_difficulty
    house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each { |r| house.send(r).paint_color = :red }

    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [])
    )

    report = Decorum::DifficultyAnalyzer.new(scenario, solution_cap: 100).analyze

    assert report[:solution_count] > 0
    assert report[:min_moves] >= 0
    assert report[:difficulty_score] < 0.5, "Trivial scenario should have low difficulty"
  end

  def test_move_distance_zero_when_initial_is_solution
    house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each { |r| house.send(r).paint_color = :red }

    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [])
    )

    report = Decorum::DifficultyAnalyzer.new(scenario, solution_cap: 1).analyze

    assert_equal 0, report[:min_moves]
  end

  def test_condition_locality_all_house_wide
    house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each { |r| house.send(r).paint_color = :red }

    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [
        Decorum::Conditions::MaxOneAntique.new
      ])
    )

    report = Decorum::DifficultyAnalyzer.new(scenario, solution_cap: 1).analyze

    assert_equal 1, report[:condition_locality][:house_wide]
    assert_equal 0, report[:condition_locality][:single_room]
    assert_equal 0, report[:condition_locality][:two_room]
  end
end

# Reuse from solver_test.rb
class LeftPaintedRed < Decorum::Condition
  def fulfilled?(player:, house:)
    house.top_left_room.paint_color == :red && house.bottom_left_room.paint_color == :red
  end
end unless defined?(LeftPaintedRed)
