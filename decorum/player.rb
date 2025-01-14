module Decorum
  class Player
    include ActiveModel::Model
    # include ActiveModel::Attributes
    # attribute :number, :integer

    attr_accessor :conditions

    def fulfilled?(house:)
      conditions.all? do |condition|
        condition.fulfilled?(player: self, house:)
      end
    end

  end
end
