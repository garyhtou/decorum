require "minitest/autorun"
require_relative "../decorum"

class ConditionsTest < Minitest::Test
  def setup
    @house = Decorum::House::TwoPlayer.new
    Decorum::House::ROOMS.each do |r|
      @house.send(r).paint_color = :red
    end
    @player = Decorum::Player.new(conditions: [])
  end

  # --- LeftPaintedBlue ---

  def test_left_painted_blue_fulfilled
    @house.top_left_room.paint_color = :blue
    @house.bottom_left_room.paint_color = :blue

    assert fulfilled?(Decorum::Conditions::LeftPaintedBlue.new)
  end

  def test_left_painted_blue_not_fulfilled
    @house.top_left_room.paint_color = :blue
    @house.bottom_left_room.paint_color = :red

    refute fulfilled?(Decorum::Conditions::LeftPaintedBlue.new)
  end

  # --- LeftNoLamps ---

  def test_left_no_lamps_fulfilled_when_empty
    assert fulfilled?(Decorum::Conditions::LeftNoLamps.new)
  end

  def test_left_no_lamps_not_fulfilled
    @house.top_left_room.lamp.assign_attributes(color: :blue, style: :modern)

    refute fulfilled?(Decorum::Conditions::LeftNoLamps.new)
  end

  # --- KitchenNoObjects ---

  def test_kitchen_no_objects_fulfilled_when_empty
    assert fulfilled?(Decorum::Conditions::KitchenNoObjects.new)
  end

  def test_kitchen_no_objects_not_fulfilled
    @house.bottom_right_room.curio.assign_attributes(color: :green, style: :modern)

    refute fulfilled?(Decorum::Conditions::KitchenNoObjects.new)
  end

  # --- MaxOneAntique ---

  def test_max_one_antique_fulfilled_with_zero
    assert fulfilled?(Decorum::Conditions::MaxOneAntique.new)
  end

  def test_max_one_antique_fulfilled_with_one
    @house.top_left_room.curio.assign_attributes(color: :blue, style: :antique)

    assert fulfilled?(Decorum::Conditions::MaxOneAntique.new)
  end

  def test_max_one_antique_not_fulfilled_with_two
    @house.top_left_room.curio.assign_attributes(color: :blue, style: :antique)
    @house.top_right_room.wall_hanging.assign_attributes(color: :green, style: :antique)

    refute fulfilled?(Decorum::Conditions::MaxOneAntique.new)
  end

  # --- MinOneAntiqueYellowLamp ---

  def test_min_one_antique_yellow_lamp_not_fulfilled
    refute fulfilled?(Decorum::Conditions::MinOneAntiqueYellowLamp.new)
  end

  def test_min_one_antique_yellow_lamp_fulfilled
    @house.top_right_room.lamp.assign_attributes(color: :yellow, style: :antique)

    assert fulfilled?(Decorum::Conditions::MinOneAntiqueYellowLamp.new)
  end

  def test_min_one_antique_yellow_lamp_wrong_color
    @house.top_right_room.lamp.assign_attributes(color: :blue, style: :modern)

    refute fulfilled?(Decorum::Conditions::MinOneAntiqueYellowLamp.new)
  end

  # --- DownstairsMinTwoObjects ---

  def test_downstairs_min_two_objects_not_fulfilled
    refute fulfilled?(Decorum::Conditions::DownstairsMinTwoObjects.new)
  end

  def test_downstairs_min_two_objects_fulfilled
    @house.bottom_left_room.lamp.assign_attributes(color: :blue, style: :modern)
    @house.bottom_right_room.curio.assign_attributes(color: :green, style: :modern)

    assert fulfilled?(Decorum::Conditions::DownstairsMinTwoObjects.new)
  end

  def test_downstairs_min_two_objects_upstairs_dont_count
    @house.top_left_room.lamp.assign_attributes(color: :blue, style: :modern)
    @house.top_right_room.curio.assign_attributes(color: :green, style: :modern)

    refute fulfilled?(Decorum::Conditions::DownstairsMinTwoObjects.new)
  end

  private

  def fulfilled?(condition)
    condition.fulfilled?(player: @player, house: @house)
  end
end
