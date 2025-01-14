module Decorum
  class House
    include ActiveModel::Model

    attr_accessor :top_left_room
    attr_accessor :top_right_room
    attr_accessor :bottom_left_room
    attr_accessor :bottom_right_room

    def rooms
      [top_left_room, top_right_room, bottom_left_room, bottom_right_room].compact
    end

    def objects
      rooms.flat_map(&:objects)
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
