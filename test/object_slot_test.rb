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

  def test_invalid_style
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :unique)

    refute slot.valid?
  end

  def test_invalid_color
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :purple, style: :modern)

    refute slot.valid?
  end

  def test_invalid_type
    slot = Decorum::ObjectSlot.new(type: :candle)

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

  # --- warm_color? / cool_color? ---

  def test_warm_color_red
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :red, style: :retro)

    assert slot.warm_color?
    refute slot.cool_color?
  end

  def test_warm_color_yellow
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :yellow, style: :antique)

    assert slot.warm_color?
    refute slot.cool_color?
  end

  def test_cool_color_blue
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :blue, style: :modern)

    assert slot.cool_color?
    refute slot.warm_color?
  end

  def test_cool_color_green
    slot = Decorum::ObjectSlot.new(type: :lamp, color: :green, style: :unusual)

    assert slot.cool_color?
    refute slot.warm_color?
  end

  def test_empty_slot_is_neither_warm_nor_cool
    slot = Decorum::ObjectSlot.new(type: :lamp)

    refute slot.warm_color?
    refute slot.cool_color?
  end

  # --- Rulebook invariants ---

  def test_colors_constant_matches_rulebook
    assert_equal %i[red blue green yellow].sort, Decorum::COLORS.sort
  end

  def test_styles_constant_matches_rulebook
    assert_equal %i[modern antique retro unusual].sort, Decorum::ObjectSlot::STYLES.sort
  end

  def test_types_constant_matches_rulebook
    assert_equal %i[lamp curio wall_hanging].sort, Decorum::ObjectSlot::TYPES.sort
  end

  def test_exactly_12_total_valid_objects
    total = Decorum::ObjectSlot::COMBINATIONS.values.sum(&:size)

    assert_equal 12, total
  end

  def test_each_type_has_all_four_colors
    Decorum::ObjectSlot::TYPES.each do |type|
      colors = Decorum::ObjectSlot::COMBINATIONS[type].map { |c| c[:color] }.sort

      assert_equal Decorum::COLORS.sort, colors,
        "Expected #{type} to have all 4 colors"
    end
  end

  def test_each_type_has_all_four_styles
    Decorum::ObjectSlot::TYPES.each do |type|
      styles = Decorum::ObjectSlot::COMBINATIONS[type].map { |c| c[:style] }.sort

      assert_equal Decorum::ObjectSlot::STYLES.sort, styles,
        "Expected #{type} to have all 4 styles"
    end
  end

  def test_no_red_antique_exists
    # Rulebook: "There are no red antiques"
    Decorum::ObjectSlot::TYPES.each do |type|
      red_antique = Decorum::ObjectSlot::COMBINATIONS[type].find do |c|
        c[:color] == :red && c[:style] == :antique
      end

      assert_nil red_antique, "Expected no red antique #{type} to exist"
    end
  end
end
