module Decorum
  module HumanizedName
    extend ActiveSupport::Concern

    class_methods do
      def humanized_name_for(*attributes, capitalize: false)
        attributes.each do |attribute|
          define_method "humanized_#{attribute}" do
            self.send(attribute).to_s.humanize(capitalize:)
          end
        end
      end
    end
  end
end
