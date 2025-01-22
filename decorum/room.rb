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

    def initialize(...)
      super(...)

      self.lamp ||= ObjectSlot.new(type: :lamp)
      self.curio ||= ObjectSlot.new(type: :curio)
      self.wall_hanging ||= ObjectSlot.new(type: :wall_hanging)
    end

    def objects
      object_slots.select(&:filled?)
    end

    def object_slots
      object_order.map { |type| send(type) }
    end

    # def has_color?(color)
    #   paint_color == color || objects.map(&:color).include?(color)
    # end

    def to_s
      header = Display.header(
        Rainbow(name.to_s.titleize).send(paint_color),
        width: (3 * 5) + (2 * 2) # 3 objects of 5 width; joined by 2 spaces
      )

      objects = object_slots.map(&:to_s)

      <<~STR
        #{header}
        #{Display.join_horizontally(objects, delimiter: "  ")}
        #{"ERRORS: " + self.errors.full_messages.to_sentence unless self.valid?}
      STR
    end

  end
end
