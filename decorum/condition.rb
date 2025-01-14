module Decorum
  class Condition
    include ActiveModel::Model

    def fulfilled?(player:, house:)
      raise NotImplementedError
    end

  end
end
