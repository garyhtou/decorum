require "minitest/autorun"
require_relative "../decorum"

class RoomTest < Minitest::Test
  def setup
    @room = Decorum::Room.new(
      name: :kitchen,
      paint_color: :red,
      object_order: %i[lamp wall_hanging curio]
    )
  end

  def test_default_object_slots_are_empty
    assert @room.lamp.empty?
    assert @room.curio.empty?
    assert @room.wall_hanging.empty?
  end

  def test_objects_returns_only_filled_slots
    assert_empty @room.objects

    @room.lamp.assign_attributes(color: :blue, style: :modern)

    assert_equal 1, @room.objects.size
    assert_equal :lamp, @room.objects.first.type
  end

  def test_object_slots_returns_all_in_order
    slots = @room.object_slots

    assert_equal 3, slots.size
    assert_equal :lamp, slots[0].type
    assert_equal :wall_hanging, slots[1].type
    assert_equal :curio, slots[2].type
  end

  def test_equality
    a = Decorum::Room.new(name: :kitchen, paint_color: :red, object_order: %i[lamp curio wall_hanging])
    b = Decorum::Room.new(name: :kitchen, paint_color: :red, object_order: %i[lamp curio wall_hanging])

    assert_equal a, b
  end

  def test_inequality_different_paint
    a = Decorum::Room.new(name: :kitchen, paint_color: :red, object_order: %i[lamp curio wall_hanging])
    b = Decorum::Room.new(name: :kitchen, paint_color: :blue, object_order: %i[lamp curio wall_hanging])

    refute_equal a, b
  end

  def test_inequality_different_objects
    a = Decorum::Room.new(name: :kitchen, paint_color: :red, object_order: %i[lamp curio wall_hanging])
    b = Decorum::Room.new(name: :kitchen, paint_color: :red, object_order: %i[lamp curio wall_hanging])
    b.lamp.assign_attributes(color: :blue, style: :modern)

    refute_equal a, b
  end

  def test_deep_dup_creates_independent_copy
    @room.lamp.assign_attributes(color: :blue, style: :modern)
    copy = @room.deep_dup

    copy.lamp.assign_attributes(color: :red, style: :retro)

    assert_equal :blue, @room.lamp.color
    assert_equal :red, copy.lamp.color
  end

  def test_deep_dup_copies_paint_color
    copy = @room.deep_dup
    copy.paint_color = :blue

    assert_equal :red, @room.paint_color
  end

  def test_hash_consistency_with_equality
    a = Decorum::Room.new(name: :kitchen, paint_color: :red, object_order: %i[lamp curio wall_hanging])
    b = Decorum::Room.new(name: :kitchen, paint_color: :red, object_order: %i[lamp curio wall_hanging])

    assert_equal a.hash, b.hash
  end

  def test_description_empty_room
    desc = @room.description

    assert_includes desc, "Kitchen"
    assert_includes desc, "red paint"
  end

  def test_description_with_objects
    @room.lamp.assign_attributes(color: :blue, style: :modern)
    desc = @room.description

    assert_includes desc, "blue modern lamp"
  end

  def test_objects_constant_matches_object_slot_types
    assert_equal Decorum::ObjectSlot::TYPES, Decorum::Room::OBJECTS
  end

  def test_valid_room_names_include_four_player_names
    assert_includes Decorum::Room::NAMES, :bedroom_a
    assert_includes Decorum::Room::NAMES, :bedroom_b
  end

  def test_all_objects_filled
    @room.lamp.assign_attributes(color: :blue, style: :modern)
    @room.curio.assign_attributes(color: :green, style: :modern)
    @room.wall_hanging.assign_attributes(color: :red, style: :modern)

    assert_equal 3, @room.objects.size
  end

  # --- Paint validation (rulebook: wall color always has a color) ---

  def test_nil_paint_color_fails_validation
    room = Decorum::Room.new(name: :kitchen, paint_color: nil, object_order: %i[lamp curio wall_hanging])

    refute room.valid?
  end

  def test_invalid_paint_color_fails_validation
    room = Decorum::Room.new(name: :kitchen, paint_color: :purple, object_order: %i[lamp curio wall_hanging])

    refute room.valid?
  end
end
