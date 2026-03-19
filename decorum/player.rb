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

    def ==(other)
      [:class, :conditions].all? do |attr|
        self.send(attr) == other.send(attr)
      end
    end

    alias_method :eql?, :==

    def initialize_dup(source)
      self.conditions = source.conditions.map(&:dup)
      super
    end

  end
end
