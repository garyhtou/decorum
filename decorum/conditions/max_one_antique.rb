module Decorum
  module Conditions
    class MaxOneAntique < ::Decorum::Condition
      def fulfilled?(player:, house:)
        house.objects.select { |object| object.style == :antique }.length <= 1
      end
    end
  end
end
