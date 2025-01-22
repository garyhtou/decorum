module Decorum
  class Condition
    include ActiveModel::Model

    def fulfilled?(player:, house:)
      raise NotImplementedError
    end

    def ==(other)
      if other.is_a?(self.class)
        # If descendant, then true if same condition class
        return true if self.class == other.class
      end

      # Otherwise, depend on default Ruby behavior
      super
    end

  end
end
