module Decorum
  module Conditions
    class DownstairsMinTwoObjects < ::Decorum::Condition
      def fulfilled?(player:, house:)
        (house.bottom_left_room.objects + house.bottom_right_room.objects).length >= 2
      end
    end
  end
end
