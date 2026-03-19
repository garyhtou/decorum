require "minitest/autorun"
require_relative "../decorum"

class ObjectSlotToSTest < Minitest::Test
  def test_empty_lamp_renders_blank_value
    slot = Decorum::ObjectSlot.new(type: :lamp)
    output = slot.to_s

    assert_includes output, "/‾\\"
    assert_includes output, "─┴─"
  end

  def test_filled_lamp_renders_style_initial
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)
    output = Rainbow.uncolor(slot.to_s)

    assert_includes output, "M"
  end

  def test_curio_uses_curio_template
    slot = Decorum::ObjectSlot.new(type: :curio)
    output = slot.to_s

    assert_includes output, "/◠\\"
    assert_includes output, "└───┘"
  end

  def test_wall_hanging_uses_wall_hanging_template
    slot = Decorum::ObjectSlot.new(type: :wall_hanging)
    output = slot.to_s

    assert_includes output, "┌-◠-┐"
    assert_includes output, "└───┘"
  end

  def test_each_style_renders_correct_initial
    { modern: "M", antique: "A", retro: "R", unusual: "U" }.each do |style, initial|
      combo = Decorum::ObjectSlot::COMBINATIONS[:lamp].find { |c| c[:style] == style }
      slot = Decorum::ObjectSlot.new(type: :lamp, **combo)

      assert_includes Rainbow.uncolor(slot.to_s), initial,
        "Expected #{style} lamp to render '#{initial}'"
    end
  end
end

class RoomToSTest < Minitest::Test
  def test_includes_room_name
    room = Decorum::Room.new(name: :kitchen, paint_color: :red, object_order: %i[lamp curio wall_hanging])
    output = Rainbow.uncolor(room.to_s)

    assert_includes output, "Kitchen"
  end

  def test_includes_all_three_object_slots
    room = Decorum::Room.new(name: :bathroom, paint_color: :blue, object_order: %i[curio wall_hanging lamp])
    output = room.to_s

    # Should contain templates for all three object types
    assert_includes output, "/◠\\"   # curio
    assert_includes output, "┌-◠-┐"  # wall_hanging
    assert_includes output, "/‾\\"   # lamp
  end

  def test_filled_object_shows_in_output
    room = Decorum::Room.new(name: :bedroom, paint_color: :green, object_order: %i[lamp curio wall_hanging])
    room.lamp.assign_attributes(color: :blue, style: :modern)
    output = Rainbow.uncolor(room.to_s)

    assert_includes output, "M"
  end
end

class HouseToSTest < Minitest::Test
  def test_includes_all_four_rooms
    house = Decorum::House::TwoPlayer.new
    house.bathroom.paint_color = :blue
    house.bedroom.paint_color = :green
    house.living_room.paint_color = :yellow
    house.kitchen.paint_color = :red
    output = Rainbow.uncolor(house.to_s)

    assert_includes output, "Bathroom"
    assert_includes output, "Bedroom"
    assert_includes output, "Living room"
    assert_includes output, "Kitchen"
  end

  def test_returns_string
    house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each { |r| house.send(r).paint_color = :red }

    assert_kind_of String, house.to_s
  end
end

class ScenarioToSTest < Minitest::Test
  def test_delegates_to_house
    scenario = Decorum::Scenarios::WelcomeHome.setup

    assert_equal scenario.house.to_s, scenario.to_s
  end
end
