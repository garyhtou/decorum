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

    def self.two_player
      new(
        top_left_room: Room.new(name: "Bathroom", object_order: %i[curio wall_hanging lamp]),
        top_right_room: Room.new(name: "Bedroom", object_order: %i[wall_hanging lamp curio]),
        bottom_left_room: Room.new(name: "Living Room", object_order: %i[curio lamp wall_hanging]),
        bottom_right_room: Room.new(name: "Kitchen", object_order: %i[lamp wall_hanging curio])
      )
    end

    def self.four_player
      # TODO: double check object order is actually the same on both physical sides
      new(
        top_left_room: Room.new(name: "Bedroom A", object_order: %i[curio wall_hanging lamp]),
        top_right_room: Room.new(name: "Bedroom B", object_order: %i[wall_hanging lamp curio]),
        bottom_left_room: Room.new(name: "Living Room", object_order: %i[curio lamp wall_hanging]),
        bottom_right_room: Room.new(name: "Kitchen", object_order: %i[lamp wall_hanging curio])
      )
    end

  end
end
