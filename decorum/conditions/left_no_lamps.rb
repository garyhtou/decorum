module Decorum
  module Conditions
    class LeftNoLamps < ::Decorum::Condition
      def fulfilled?(player:, house:)
        house.top_left_room.lamp.empty? && house.bottom_left_room.lamp.empty?
      end
    end
  end
end
