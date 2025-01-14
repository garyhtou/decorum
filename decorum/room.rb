module Decorum
  class Room
    include ActiveModel::Model

    NAMES = %i[bedroom bathroom kitchen living_room]
    attr_accessor :name
    validates :name, presence: true, inclusion: { in: NAMES }

    attr_accessor :wall_color
    validates :wall_color, presence: true, inclusion: { in: Decorum::COLORS }

    attr_accessor :lamp
    attr_accessor :curio
    attr_accessor :wall_hanging

    attr_accessor :object_order
    validates :object_order, presence: true, length: { is: 3 }
    # validate do
    #   errors.add(:object_order, "must contain all objects") unless object_order.include?(:lamp) && object_order.include?(:curio) && object_order.include?(:wall_hanging)
    # end

    def objects
      object_order.map { |object| send(object) }.compact
    end

    # def has_color?(color)
    #   paint_color == color || objects.map(&:color).include?(color)
    # end

  end
end
