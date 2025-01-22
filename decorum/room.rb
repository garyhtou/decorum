module Decorum
  class Room
    include ActiveModel::Model
    include HumanizedName
    include GeneratableChoices

    NAMES = %i[bedroom bathroom kitchen living_room]
    attr_accessor :name
    validates :name, presence: true, inclusion: { in: NAMES }

    attr_accessor :paint_color
    validates :paint_color, presence: true, inclusion: { in: Decorum::COLORS }

    OBJECTS = %i[lamp curio wall_hanging]
    attr_accessor :lamp
    attr_accessor :curio
    attr_accessor :wall_hanging

    attr_accessor :object_order
    validates :object_order, presence: true, length: { is: 3 }
    # validate do
    #   errors.add(:object_order, "must contain all objects") unless object_order.include?(:lamp) && object_order.include?(:curio) && object_order.include?(:wall_hanging)
    # end

    humanized_name_for :name, capitalize: true
    humanized_name_for :paint_color

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

    def possible_choices
      choices = ::Decorum::COLORS.map { |color| { paint_color: color } }

      OBJECTS.each do |object|
        # For each object (lamp, curio, wall hanging), get all possible choices
        self.send(object).possible_choices.each do |choice|
          choices << { object => choice }
        end
      end

      generate_choices(choices)
    end

    def description
      list = ["#{humanized_paint_color} paint"]
      list.concat(objects.map(&:description))
      "#{name.to_s.titleize} with #{list.to_sentence}"
    end

    def ==(other)
      [:class, :name, :paint_color, *OBJECTS, :object_order].all? do |attr|
        self.send(attr) == other.send(attr)
      end
    end

    alias_method :eql?, :==

    def initialize_dup(source)
      [*OBJECTS, :object_order].each do |attr|
        self.send("#{attr}=", source.send(attr).deep_dup)
      end

      super
    end

    def to_s
      header = Display.header(
        Rainbow(humanized_name).send(paint_color),
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
