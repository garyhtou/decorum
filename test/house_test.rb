require "minitest/autorun"
require_relative "../decorum"

class HouseTest < Minitest::Test
  def setup
    @house = Decorum::House::TwoPlayer.new
  end

  def test_two_player_has_four_rooms
    assert_equal 4, @house.rooms.size
  end

  def test_two_player_room_aliases
    assert_equal :bathroom, @house.bathroom.name
    assert_equal :bedroom, @house.bedroom.name
    assert_equal :living_room, @house.living_room.name
    assert_equal :kitchen, @house.kitchen.name
  end

  def test_two_player_room_positions
    assert_equal @house.bathroom, @house.top_left_room
    assert_equal @house.bedroom, @house.top_right_room
    assert_equal @house.living_room, @house.bottom_left_room
    assert_equal @house.kitchen, @house.bottom_right_room
  end

  def test_objects_returns_all_filled_objects
    assert_empty @house.objects

    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    @house.kitchen.curio.assign_attributes(color: :green, style: :modern)

    assert_equal 2, @house.objects.size
  end

  def test_rooms_compacts_nil_rooms
    @house.top_left_room = nil

    assert_equal 3, @house.rooms.size
  end

  def test_equality
    a = Decorum::House::TwoPlayer.new
    b = Decorum::House::TwoPlayer.new

    assert_equal a, b
  end

  def test_inequality_different_paint
    a = Decorum::House::TwoPlayer.new
    b = Decorum::House::TwoPlayer.new
    b.bathroom.paint_color = :blue

    refute_equal a, b
  end

  def test_deep_dup_creates_independent_copy
    @house.bathroom.paint_color = :blue
    copy = @house.deep_dup

    copy.bathroom.paint_color = :red

    assert_equal :blue, @house.bathroom.paint_color
    assert_equal :red, copy.bathroom.paint_color
  end

  def test_deep_dup_isolates_objects
    @house.kitchen.lamp.assign_attributes(color: :blue, style: :modern)
    copy = @house.deep_dup

    copy.kitchen.lamp.assign_attributes(color: :red, style: :retro)

    assert_equal :blue, @house.kitchen.lamp.color
    assert_equal :red, copy.kitchen.lamp.color
  end

  def test_hash_consistency_with_equality
    a = Decorum::House::TwoPlayer.new
    b = Decorum::House::TwoPlayer.new

    assert_equal a.hash, b.hash
  end

  def test_clear_nils_all_rooms
    @house.clear!

    Decorum::House::ROOMS.each do |r|
      assert_nil @house.send(r), "Expected #{r} to be nil after clear!"
    end
  end

  def test_clear_returns_self
    result = @house.clear!

    assert_same @house, result
  end
end
