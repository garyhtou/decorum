module Decorum
  class Player
    include ActiveModel::Model
    include ActiveModel::Attributes

    attribute :number, :integer

    attr_accessor :conditions

    def fulfilled?
      conditions.all?(&:fulfilled?)
    end

  end
end
