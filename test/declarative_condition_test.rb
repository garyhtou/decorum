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

  private

  def build_condition(**definition)
    Decorum::Conditions::Declarative.new(definition: definition)
  end

  def fulfilled?(condition)
    condition.fulfilled?(player: @player, house: @house)
  end
end
