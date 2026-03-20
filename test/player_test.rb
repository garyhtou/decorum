require "minitest/autorun"
require_relative "../decorum"

class PlayerTest < Minitest::Test
  def test_fulfilled_with_all_conditions_met
    house = Decorum::House::TwoPlayer.new
    house.bathroom.paint_color = :blue
    house.living_room.paint_color = :blue

    player = Decorum::Player.new(conditions: [
      Decorum::Conditions::LeftPaintedBlue.new
    ])

    assert player.fulfilled?(house: house)
  end

  def test_not_fulfilled_when_condition_fails
    house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each { |r| house.send(r).paint_color = :red }

    player = Decorum::Player.new(conditions: [
      Decorum::Conditions::LeftPaintedBlue.new
    ])

    refute player.fulfilled?(house: house)
  end

  def test_fulfilled_with_empty_conditions
    house = Decorum::House::TwoPlayer.new

    player = Decorum::Player.new(conditions: [])

    assert player.fulfilled?(house: house)
  end

  def test_fulfilled_requires_all_conditions
    house = Decorum::House::TwoPlayer.new
    house.bathroom.paint_color = :blue
    house.living_room.paint_color = :blue

    player = Decorum::Player.new(conditions: [
      Decorum::Conditions::LeftPaintedBlue.new,
      Decorum::Conditions::MinOneAntiqueYellowLamp.new,
    ])

    refute player.fulfilled?(house: house), "Should fail when not all conditions met"
  end

  def test_equality
    a = Decorum::Player.new(conditions: [Decorum::Conditions::LeftPaintedBlue.new])
    b = Decorum::Player.new(conditions: [Decorum::Conditions::LeftPaintedBlue.new])

    assert_equal a, b
  end

  def test_inequality_different_conditions
    a = Decorum::Player.new(conditions: [Decorum::Conditions::LeftPaintedBlue.new])
    b = Decorum::Player.new(conditions: [Decorum::Conditions::KitchenNoObjects.new])

    refute_equal a, b
  end

  def test_deep_dup_isolates_conditions
    player = Decorum::Player.new(conditions: [
      Decorum::Conditions::LeftPaintedBlue.new
    ])
    copy = player.deep_dup

    assert_equal player.conditions.size, copy.conditions.size
    refute_same player.conditions.first, copy.conditions.first
  end
end
