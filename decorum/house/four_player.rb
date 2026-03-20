module Decorum
  class House
    class FourPlayer < House
      ROOM_NAMES = {
        bedroom_a: :top_left_room,
        bedroom_b: :top_right_room,
        living_room: :bottom_left_room,
        kitchen: :bottom_right_room,
      }.freeze

      ROOM_NAMES.each { |name, position| alias_attribute name, position }

      def initialize
        self.top_left_room = Room.new(name: :bedroom_a, object_order: %i[curio wall_hanging lamp])
        self.top_right_room = Room.new(name: :bedroom_b, object_order: %i[wall_hanging lamp curio])
        self.bottom_left_room = Room.new(name: :living_room, object_order: %i[curio lamp wall_hanging])
        self.bottom_right_room = Room.new(name: :kitchen, object_order: %i[lamp wall_hanging curio])
      end

    end
  end
end
