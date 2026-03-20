require "minitest/autorun"
require_relative "../decorum"

class HumanizedNameTest < Minitest::Test
  def test_humanized_type
    slot = Decorum::ObjectSlot.new(type: :wall_hanging)

    assert_equal "wall hanging", slot.humanized_type
  end

  def test_humanized_color
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)

    assert_equal "blue", slot.humanized_color
  end

  def test_humanized_style
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)

    assert_equal "modern", slot.humanized_style
  end

  def test_humanized_name_nil_value
    slot = Decorum::ObjectSlot.new(type: :lamp)

    assert_equal "", slot.humanized_color
    assert_equal "", slot.humanized_style
  end

  def test_room_humanized_name_capitalized
    room = Decorum::Room.new(name: :living_room, paint_color: :red, object_order: %i[lamp curio wall_hanging])

    assert_equal "Living room", room.humanized_name
  end

  def test_room_humanized_paint_color
    room = Decorum::Room.new(name: :kitchen, paint_color: :blue, object_order: %i[lamp curio wall_hanging])

    assert_equal "blue", room.humanized_paint_color
  end
end
