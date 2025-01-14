module Decorum
  module Conditions
    class LeftPaintedBlue < ::Decorum::Condition
      def fulfilled?(player:, house:)
        house.top_left_room.wall_color == :blue && house.bottom_left_room.wall_color == :blue
      end
    end
  end
end
