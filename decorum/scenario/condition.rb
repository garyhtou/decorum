module Decorum
  class Scenario
    class Condition
      include ActiveModel::Model

      attr_accessor :player

      def fulfilled?

      end

    end
  end
end
