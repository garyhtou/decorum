module Decorum
  class House
    include ActiveModel::Model
    include GeneratableChoices

    ROOMS = %i[top_left_room top_right_room bottom_left_room bottom_right_room].freeze
    attr_accessor :top_left_room
    attr_accessor :top_right_room
    attr_accessor :bottom_left_room
    attr_accessor :bottom_right_room

    def rooms
      ROOMS.map { |room| send(room) }.compact
    end

    def objects
      rooms.flat_map(&:objects)
    end

    def possible_choices
      choices = ROOMS.flat_map do |room|
        self.send(room).possible_choices.map { |choice| { room => choice } }
      end

      generate_choices(choices)
    end

    def description
      rooms.map(&:description).join(".\n")
    end

    def ==(other)
      [:class, *ROOMS].all? do |attr|
        self.send(attr) == other.send(attr)
      end
    end

    alias_method :eql?, :==

    def initialize_dup(source)
      ROOMS.each do |attr|
        self.send("#{attr}=", source.send(attr).deep_dup)
      end

      super
    end

    def to_s
      delimiter = " " * 5
      top = Display.join_horizontally([top_left_room.to_s, top_right_room.to_s], delimiter:)
      bottom = Display.join_horizontally([bottom_left_room.to_s, bottom_right_room.to_s], delimiter:)

      <<~STR
        #{top}

        #{bottom}
      STR
    end
  end
end
