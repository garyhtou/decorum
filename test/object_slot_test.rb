require "minitest/autorun"
require_relative "../decorum"

class ObjectSlotTest < Minitest::Test
  def test_empty_by_default
    slot = Decorum::ObjectSlot.new(type: :lamp)

    assert slot.empty?
    refute slot.filled?
  end

  def test_filled_when_color_and_style_set
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)

    refute slot.empty?
    assert slot.filled?
  end

  def test_valid_lamp_combinations
    Decorum::ObjectSlot::COMBINATIONS[:lamp].each do |combo|
      slot = Decorum::ObjectSlot.new(type: :lamp, **combo)
      assert slot.valid?, "Expected #{combo} to be valid for lamp"
    end
  end

  def test_valid_curio_combinations
    Decorum::ObjectSlot::COMBINATIONS[:curio].each do |combo|
      slot = Decorum::ObjectSlot.new(type: :curio, **combo)
      assert slot.valid?, "Expected #{combo} to be valid for curio"
    end
  end

  def test_valid_wall_hanging_combinations
    Decorum::ObjectSlot::COMBINATIONS[:wall_hanging].each do |combo|
      slot = Decorum::ObjectSlot.new(type: :wall_hanging, **combo)
      assert slot.valid?, "Expected #{combo} to be valid for wall_hanging"
    end
  end

  def test_invalid_combination
    # blue/antique is a valid curio combo, not a valid lamp combo
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :antique)

    refute slot.valid?
  end

  def test_empty_slot_is_valid
    slot = Decorum::ObjectSlot.new(type: :lamp)

    assert slot.valid?
  end

  def test_equality
    a = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)
    b = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)

    assert_equal a, b
  end

  def test_inequality_different_color
    a = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)
    b = Decorum::ObjectSlot.new(type: :lamp, color: :red, style: :retro)

    refute_equal a, b
  end

  def test_inequality_different_type
    a = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)
    b = Decorum::ObjectSlot.new(type: :curio, color: :blue, style: :antique)

    refute_equal a, b
  end

  def test_empty_slots_are_equal
    a = Decorum::ObjectSlot.new(type: :lamp)
    b = Decorum::ObjectSlot.new(type: :lamp)

    assert_equal a, b
  end

  def test_hash_consistency_with_equality
    a = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)
    b = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)

    assert_equal a.hash, b.hash
  end

  def test_each_type_has_four_combinations
    Decorum::ObjectSlot::TYPES.each do |type|
      assert_equal 4, Decorum::ObjectSlot::COMBINATIONS[type].size,
        "Expected 4 combinations for #{type}"
    end
  end

  def test_description_when_filled
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)

    assert_equal "blue modern lamp", slot.description
  end

  def test_description_when_empty
    slot = Decorum::ObjectSlot.new(type: :curio)

    assert_equal "empty curio", slot.description
  end
end
