require "minitest/autorun"
require_relative "../decorum"

class DeclarativeConditionTest < Minitest::Test
  def setup
    @house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each { |r| @house.send(r).paint_color = :red }
    @player = Decorum::Player.new(conditions: [])
  end

  # --- Scope tests ---

  def test_house_scope
    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    @house.kitchen.curio.assign_attributes(color: :green, style: :modern)

    cond = build_condition(scope: "house", subject: "objects", assertion: { count: { min: 2 } })
    assert fulfilled?(cond)
  end

  def test_room_name_scope
    cond = build_condition(scope: "kitchen", subject: "objects", assertion: { count: { max: 0 } })
    assert fulfilled?(cond)

    @house.kitchen.lamp.assign_attributes(color: :blue, style: :modern)
    refute fulfilled?(cond)
  end

  def test_upstairs_scope
    @house.bathroom.paint_color = :blue
    @house.bedroom.paint_color = :blue

    cond = build_condition(scope: "upstairs", subject: "paint_color", assertion: { equals: "blue" })
    assert fulfilled?(cond)
  end

  def test_downstairs_scope
    @house.living_room.lamp.assign_attributes(color: :blue, style: :modern)
    @house.kitchen.curio.assign_attributes(color: :green, style: :modern)

    cond = build_condition(scope: "downstairs", subject: "objects", assertion: { count: { min: 2 } })
    assert fulfilled?(cond)
  end

  def test_left_side_scope
    @house.bathroom.paint_color = :green
    @house.living_room.paint_color = :green

    cond = build_condition(scope: "left_side", subject: "paint_color", assertion: { equals: "green" })
    assert fulfilled?(cond)
  end

  def test_right_side_scope
    @house.bedroom.paint_color = :yellow
    @house.kitchen.paint_color = :yellow

    cond = build_condition(scope: "right_side", subject: "paint_color", assertion: { equals: "yellow" })
    assert fulfilled?(cond)
  end

  # --- Subject tests ---

  def test_paint_color_subject
    @house.bathroom.paint_color = :blue
    @house.living_room.paint_color = :blue

    cond = build_condition(scope: "left_side", subject: "paint_color", assertion: { equals: "blue" })
    assert fulfilled?(cond)
  end

  def test_objects_subject
    cond = build_condition(scope: "house", subject: "objects", assertion: { count: { max: 0 } })
    assert fulfilled?(cond)

    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    refute fulfilled?(cond)
  end

  def test_lamps_subject
    cond = build_condition(scope: "left_side", subject: "lamps", assertion: { count: { max: 0 } })
    assert fulfilled?(cond)

    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    refute fulfilled?(cond)
  end

  def test_empty_slots_subject
    # All slots start empty = 12 empty slots (4 rooms x 3 slots)
    cond = build_condition(scope: "house", subject: "empty_slots", assertion: { count: { min: 12 } })
    assert fulfilled?(cond)

    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    refute fulfilled?(cond)
  end

  def test_features_subject
    @house.bathroom.paint_color = :blue
    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)

    # Features = paint colors + object colors
    cond = build_condition(scope: "bathroom", subject: "features", assertion: { includes: "blue" })
    assert fulfilled?(cond)
  end

  # --- Filter tests ---

  def test_filter_by_style
    @house.bathroom.curio.assign_attributes(color: :blue, style: :antique)

    cond = build_condition(
      scope: "house", subject: "objects",
      filter: { style: "antique" },
      assertion: { count: { max: 1 } }
    )
    assert fulfilled?(cond)

    @house.bedroom.wall_hanging.assign_attributes(color: :green, style: :antique)
    refute fulfilled?(cond)
  end

  def test_filter_by_multiple_attributes
    @house.bedroom.lamp.assign_attributes(color: :yellow, style: :antique)

    cond = build_condition(
      scope: "house", subject: "objects",
      filter: { type: "lamp", color: "yellow", style: "antique" },
      assertion: { count: { min: 1 } }
    )
    assert fulfilled?(cond)
  end

  def test_filter_no_match
    @house.bedroom.lamp.assign_attributes(color: :blue, style: :modern)

    cond = build_condition(
      scope: "house", subject: "objects",
      filter: { color: "yellow" },
      assertion: { count: { min: 1 } }
    )
    refute fulfilled?(cond)
  end

  # --- Assertion tests ---

  def test_equals_assertion
    @house.bathroom.paint_color = :blue
    @house.living_room.paint_color = :blue

    cond = build_condition(scope: "left_side", subject: "paint_color", assertion: { equals: "blue" })
    assert fulfilled?(cond)

    @house.living_room.paint_color = :red
    refute fulfilled?(cond)
  end

  def test_not_equals_assertion
    cond = build_condition(scope: "left_side", subject: "paint_color", assertion: { not_equals: "blue" })
    assert fulfilled?(cond)

    @house.bathroom.paint_color = :blue
    refute fulfilled?(cond)
  end

  def test_includes_assertion
    @house.bathroom.paint_color = :blue

    cond = build_condition(scope: "bathroom", subject: "features", assertion: { includes: "blue" })
    assert fulfilled?(cond)
  end

  def test_excludes_assertion
    cond = build_condition(scope: "bathroom", subject: "features", assertion: { excludes: "blue" })
    assert fulfilled?(cond)

    @house.bathroom.paint_color = :blue
    refute fulfilled?(cond)
  end

  def test_count_min_assertion
    cond = build_condition(scope: "house", subject: "objects", assertion: { count: { min: 1 } })
    refute fulfilled?(cond)

    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    assert fulfilled?(cond)
  end

  def test_count_max_assertion
    cond = build_condition(scope: "house", subject: "objects", assertion: { count: { max: 1 } })
    assert fulfilled?(cond)

    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    assert fulfilled?(cond)

    @house.kitchen.curio.assign_attributes(color: :green, style: :modern)
    refute fulfilled?(cond)
  end

  def test_count_equals_assertion
    cond = build_condition(scope: "house", subject: "objects", assertion: { count: { equals: 0 } })
    assert fulfilled?(cond)

    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    refute fulfilled?(cond)
  end

  def test_count_min_and_max_assertion
    cond = build_condition(scope: "house", subject: "objects", assertion: { count: { min: 1, max: 2 } })
    refute fulfilled?(cond)

    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    assert fulfilled?(cond)

    @house.kitchen.curio.assign_attributes(color: :green, style: :modern)
    assert fulfilled?(cond)

    @house.bedroom.wall_hanging.assign_attributes(color: :red, style: :modern)
    refute fulfilled?(cond)
  end

  # --- Matches existing Ruby conditions ---

  def test_matches_left_painted_blue
    declarative = build_condition(scope: "left_side", subject: "paint_color", assertion: { equals: "blue" })
    ruby_cond = Decorum::Conditions::LeftPaintedBlue.new

    @house.bathroom.paint_color = :blue
    @house.living_room.paint_color = :blue
    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)

    @house.living_room.paint_color = :red
    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)
  end

  def test_matches_kitchen_no_objects
    declarative = build_condition(scope: "kitchen", subject: "objects", assertion: { count: { max: 0 } })
    ruby_cond = Decorum::Conditions::KitchenNoObjects.new

    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)

    @house.kitchen.lamp.assign_attributes(color: :blue, style: :modern)
    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)
  end

  def test_matches_left_no_lamps
    declarative = build_condition(scope: "left_side", subject: "lamps", assertion: { count: { max: 0 } })
    ruby_cond = Decorum::Conditions::LeftNoLamps.new

    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)

    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)
  end

  def test_matches_max_one_antique
    declarative = build_condition(scope: "house", subject: "objects", filter: { style: "antique" }, assertion: { count: { max: 1 } })
    ruby_cond = Decorum::Conditions::MaxOneAntique.new

    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)

    @house.bathroom.curio.assign_attributes(color: :blue, style: :antique)
    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)

    @house.bedroom.wall_hanging.assign_attributes(color: :green, style: :antique)
    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)
  end

  def test_matches_min_one_antique_yellow_lamp
    declarative = build_condition(
      scope: "house", subject: "objects",
      filter: { type: "lamp", color: "yellow", style: "antique" },
      assertion: { count: { min: 1 } }
    )
    ruby_cond = Decorum::Conditions::MinOneAntiqueYellowLamp.new

    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)

    @house.bedroom.lamp.assign_attributes(color: :yellow, style: :antique)
    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)
  end

  def test_matches_downstairs_min_two_objects
    declarative = build_condition(scope: "downstairs", subject: "objects", assertion: { count: { min: 2 } })
    ruby_cond = Decorum::Conditions::DownstairsMinTwoObjects.new

    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)

    @house.living_room.lamp.assign_attributes(color: :blue, style: :modern)
    @house.kitchen.curio.assign_attributes(color: :green, style: :modern)
    assert_equal ruby_cond.fulfilled?(player: @player, house: @house), fulfilled?(declarative)
  end

  # --- covers assertion ---

  def test_covers_with_simple_values
    Decorum::House::ROOMS.each_with_index do |r, i|
      @house.send(r).paint_color = Decorum::COLORS[i]
    end

    cond = build_condition(
      scope: "house", subject: "paint_color",
      assertion: { covers: { values: %w[red blue green yellow] } }
    )
    assert fulfilled?(cond)
  end

  def test_covers_fails_when_value_missing
    Decorum::House::ROOMS.each { |r| @house.send(r).paint_color = :red }

    cond = build_condition(
      scope: "house", subject: "paint_color",
      assertion: { covers: { values: %w[red blue] } }
    )
    refute fulfilled?(cond)
  end

  def test_covers_with_attribute
    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    @house.bedroom.curio.assign_attributes(color: :green, style: :modern)
    @house.living_room.wall_hanging.assign_attributes(color: :red, style: :modern)

    cond = build_condition(
      scope: "house", subject: "objects",
      assertion: { covers: { attribute: "type", values: %w[lamp curio wall_hanging] } }
    )
    assert fulfilled?(cond)
  end

  def test_covers_fails_when_attribute_value_missing
    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)

    cond = build_condition(
      scope: "house", subject: "objects",
      assertion: { covers: { attribute: "style", values: %w[modern antique] } }
    )
    refute fulfilled?(cond)
  end

  # --- unique assertion ---

  def test_unique_passes_when_all_same
    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    @house.bathroom.curio.assign_attributes(color: :green, style: :modern)

    cond = build_condition(
      scope: "bathroom", subject: "objects",
      assertion: { unique: { attribute: "style", max: 1 } }
    )
    assert fulfilled?(cond)
  end

  def test_unique_fails_when_different
    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    @house.bathroom.curio.assign_attributes(color: :blue, style: :antique)

    cond = build_condition(
      scope: "bathroom", subject: "objects",
      assertion: { unique: { attribute: "style", max: 1 } }
    )
    refute fulfilled?(cond)
  end

  def test_unique_passes_with_empty_room
    cond = build_condition(
      scope: "bathroom", subject: "objects",
      assertion: { unique: { attribute: "style", max: 1 } }
    )
    assert fulfilled?(cond), "Empty room has 0 distinct styles, which is ≤ 1"
  end

  # --- each_room scope ---

  def test_each_room_all_pass
    # All rooms empty → 0 distinct styles ≤ 1
    cond = build_condition(
      scope: "each_room", subject: "objects",
      assertion: { unique: { attribute: "style", max: 1 } }
    )
    assert fulfilled?(cond)
  end

  def test_each_room_one_fails
    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    @house.bathroom.curio.assign_attributes(color: :blue, style: :antique)

    cond = build_condition(
      scope: "each_room", subject: "objects",
      assertion: { unique: { attribute: "style", max: 1 } }
    )
    refute fulfilled?(cond), "Bathroom has 2 distinct styles"
  end

  def test_each_room_scoped_to_downstairs
    # Only downstairs rooms checked
    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)
    @house.bathroom.curio.assign_attributes(color: :blue, style: :antique)

    cond = build_condition(
      scope: "each_room_downstairs", subject: "objects",
      assertion: { unique: { attribute: "style", max: 1 } }
    )
    assert fulfilled?(cond), "Downstairs rooms are fine, upstairs violation shouldn't matter"
  end

  # --- Error handling ---

  def test_unknown_scope_raises
    cond = build_condition(scope: "garage", subject: "objects", assertion: { count: { min: 0 } })

    assert_raises(ArgumentError) { fulfilled?(cond) }
  end

  def test_unknown_subject_raises
    cond = build_condition(scope: "house", subject: "windows", assertion: { count: { min: 0 } })

    assert_raises(ArgumentError) { fulfilled?(cond) }
  end

  def test_unknown_assertion_raises
    cond = build_condition(scope: "house", subject: "objects", assertion: { vibrates: true })

    assert_raises(ArgumentError) { fulfilled?(cond) }
  end

  # --- Declarative equality ---

  def test_equality
    a = build_condition(scope: "house", subject: "objects", assertion: { count: { min: 1 } })
    b = build_condition(scope: "house", subject: "objects", assertion: { count: { min: 1 } })

    assert_equal a, b
  end

  def test_inequality
    a = build_condition(scope: "house", subject: "objects", assertion: { count: { min: 1 } })
    b = build_condition(scope: "kitchen", subject: "objects", assertion: { count: { min: 1 } })

    refute_equal a, b
  end

  # --- Wall hangings / curios subjects ---

  def test_curios_subject
    cond = build_condition(scope: "house", subject: "curios", assertion: { count: { min: 1 } })
    refute fulfilled?(cond)

    @house.bathroom.curio.assign_attributes(color: :green, style: :modern)
    assert fulfilled?(cond)
  end

  def test_wall_hangings_subject
    cond = build_condition(scope: "house", subject: "wall_hangings", assertion: { count: { min: 1 } })
    refute fulfilled?(cond)

    @house.bathroom.wall_hanging.assign_attributes(color: :red, style: :modern)
    assert fulfilled?(cond)
  end

  # --- "Feature" = objects + wall paint (rulebook definition) ---

  def test_features_includes_wall_paint_color
    @house.bathroom.paint_color = :green

    cond = build_condition(scope: "bathroom", subject: "features", assertion: { includes: "green" })
    assert fulfilled?(cond)
  end

  def test_features_includes_object_color
    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)

    cond = build_condition(scope: "bathroom", subject: "features", assertion: { includes: "blue" })
    assert fulfilled?(cond)
  end

  def test_features_does_not_include_styles
    @house.bathroom.lamp.assign_attributes(color: :blue, style: :modern)

    # "modern" is a style, not a color — features should not include it
    cond = build_condition(scope: "bathroom", subject: "features", assertion: { includes: "modern" })
    refute fulfilled?(cond)
  end

  private

  def build_condition(**definition)
    Decorum::Conditions::Declarative.new(definition: definition)
  end

  def fulfilled?(condition)
    condition.fulfilled?(player: @player, house: @house)
  end
end
