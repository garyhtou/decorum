module Decorum
  module Conditions
    class LeftNoLamps < ::Decorum::Condition
      def fulfilled?(player:, house:)
        house.top_left_room.lamp.nil? && house.bottom_left_room.lamp.nil?
      end
    end
  end
end
