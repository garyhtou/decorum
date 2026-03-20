require "minitest/autorun"
require_relative "../decorum"

class SearchSpaceTest < Minitest::Test
  def setup
    @scenario = Decorum::Scenarios::WelcomeHome.setup
    @space = Decorum::SearchSpace.new(@scenario)
  end

  def test_domains_have_entries_for_all_rooms
    assert_equal 4, @space.domains.size

    Decorum::House::ROOMS.each do |pos|
      assert @space.domains.key?(pos), "Expected domain for #{pos}"
    end
  end

  def test_unfiltered_domains_are_500_each
    @space.unfiltered_domain_sizes.each do |pos, size|
      assert_equal 500, size, "Expected 500 unfiltered states for #{pos}"
    end
  end

  def test_unary_filtering_reduces_kitchen
    # KitchenNoObjects should reduce kitchen to 4 states (paint only)
    assert @space.domains[:bottom_right_room].size <= 4
  end

  def test_room_order_has_all_positions
    assert_equal 4, @space.room_order.size
    Decorum::House::ROOMS.each do |pos|
      assert_includes @space.room_order, pos
    end
  end

  def test_most_constrained_room_first
    # Kitchen (4 states) should be ordered before rooms with 500 states
    assert_equal :bottom_right_room, @space.room_order.first
  end

  def test_condition_entries_count
    assert_equal 6, @space.condition_entries.size
  end

  def test_condition_entries_have_required_rooms
    @space.condition_entries.each do |entry|
      assert entry[:required_rooms].is_a?(Array)
      assert entry[:required_rooms].size > 0
      assert_kind_of Decorum::Condition, entry[:condition]
      assert_kind_of Decorum::Player, entry[:player]
    end
  end

  def test_conditions_by_trigger_covers_conditions
    total = @space.conditions_by_trigger.values.flatten.size

    assert_equal 6, total, "All 6 conditions should be triggered somewhere"
  end

  def test_safe_check_returns_true_on_nil_room
    house = Decorum::House::TwoPlayer.new.clear!
    entry = {
      condition: Decorum::Conditions::LeftPaintedBlue.new,
      player: Decorum::Player.new(conditions: [])
    }

    # Rooms are nil, should rescue NoMethodError and return true
    assert @space.safe_check(entry, house)
  end

  def test_safe_check_returns_condition_result
    house = Decorum::House::TwoPlayer.new
    house.bathroom.paint_color = :blue
    house.living_room.paint_color = :blue

    entry = {
      condition: Decorum::Conditions::LeftPaintedBlue.new,
      player: Decorum::Player.new(conditions: [])
    }

    assert @space.safe_check(entry, house)

    house.bathroom.paint_color = :red
    refute @space.safe_check(entry, house)
  end

  def test_works_with_no_conditions
    house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each { |r| house.send(r).paint_color = :red }

    scenario = Decorum::Scenario.new(
      house: house,
      player_one: Decorum::Player.new(conditions: [])
    )

    space = Decorum::SearchSpace.new(scenario)

    assert_equal 0, space.condition_entries.size
    assert_equal 4, space.room_order.size
    # All domains should be unfiltered (500 each)
    space.domains.each do |_, states|
      assert_equal 500, states.size
    end
  end
end
