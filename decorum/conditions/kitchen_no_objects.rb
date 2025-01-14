module Decorum
  module Conditions
    class KitchenNoObjects < ::Decorum::Condition
      def fulfilled?(player:, house:)
        house.bottom_right_room.objects.empty?
      end
    end
  end
end
