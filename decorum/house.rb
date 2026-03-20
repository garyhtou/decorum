module Decorum
  class House
    include ActiveModel::Model

    ROOMS = %i[top_left_room top_right_room bottom_left_room bottom_right_room].freeze

    POSITION_GROUPS = {
      upstairs: %i[top_left_room top_right_room],
      downstairs: %i[bottom_left_room bottom_right_room],
      left_side: %i[top_left_room bottom_left_room],
      right_side: %i[top_right_room bottom_right_room],
    }.freeze

    attr_accessor :top_left_room
    attr_accessor :top_right_room
    attr_accessor :bottom_left_room
    attr_accessor :bottom_right_room

    def clear!
      ROOMS.each { |r| send("#{r}=", nil) }
      self
    end

    def rooms
      ROOMS.map { |room| send(room) }.compact
    end

    def objects
      rooms.flat_map(&:objects)
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

    def hash
      [*ROOMS].map { |attr| self.send(attr) }.hash
    end

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
