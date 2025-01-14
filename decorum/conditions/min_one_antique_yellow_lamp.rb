module Decorum
  module Conditions
    class MinOneAntiqueYellowLamp < ::Decorum::Condition
      def fulfilled?(player:, house:)
        house.objects.select do |object|
          object.style == :antique && object.color == :yellow && object.type == :lamp
        end.length >= 1
      end
    end
  end
end
