module Decorum
  class Room
    include ActiveModel::Model

    NAMES = %i[bedroom bathroom kitchen living_room]
    attr_accessor :name
    validates :name, presence: true, inclusion: { in: NAMES }

    attr_accessor :paint_color
    validates :paint_color, presence: true, inclusion: { in: Decorum::COLORS }

    attr_accessor :lamp
    attr_accessor :curio
    attr_accessor :wall_hanging

    attr_accessor :object_order
    validates :object_order, presence: true, length: { is: 3 }
    # validate do
    #   errors.add(:object_order, "must contain all objects") unless object_order.include?(:lamp) && object_order.include?(:curio) && object_order.include?(:wall_hanging)
    # end

    def objects
      object_order.map { |type| send(type) }.compact
    end

    # def has_color?(color)
    #   paint_color == color || objects.map(&:color).include?(color)
    # end

    def to_s
      objects = object_order.map { |type| [type, send(type)] }.map do |type, object|
        if object.present?
          object.to_s
        else
          Decorum::Object.to_s(type:, value: "◌")
        end
      end

      header = Display.header(
        Rainbow(name.to_s.titleize).send(paint_color),
        width: (3 * 5) + (2 * 2) # 3 objects of 5 width; joined by 2 spaces
      )

      <<~STR
        #{header}
        #{Display.join_horizontally(objects, delimiter: "  ")}
        #{"ERRORS: " + self.errors.full_messages.to_sentence unless self.valid?}
      STR
    end

  end
end
