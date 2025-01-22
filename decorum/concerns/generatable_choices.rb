module Decorum
  module GeneratableChoices
    extend ActiveSupport::Concern

    included do
      def generate_choices(sub_choices)
        choices = sub_choices.map do |choice|
          self.deep_dup.tap { |object| object.assign_attributes(choice) }
        end

        choices.excluding(self)
      end
    end
  end
end
