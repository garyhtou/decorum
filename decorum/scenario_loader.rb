require "json"

module Decorum
  class ScenarioLoader
    HOUSE_TYPES = {
      "two_player" => House::TwoPlayer,
      "four_player" => House::FourPlayer,
    }.freeze

    def self.load_file(path)
      load(File.read(path))
    end

    def self.load(json_string)
      data = JSON.parse(json_string, symbolize_names: true)
      new(data).build
    end

    def initialize(data)
      @data = data
    end

    def build
      house = build_house
      players = build_players

      scenario_attrs = { house: house }
      Scenario::PLAYERS.each_with_index do |player_sym, i|
        scenario_attrs[player_sym] = players[i] if players[i]
      end

      Scenario.new(**scenario_attrs)
    end

    private

    def build_house
      house_class = HOUSE_TYPES[@data[:house_type]] ||
        raise(ArgumentError, "Unknown house_type: #{@data[:house_type]}")

      house = house_class.new

      @data[:initial_state]&.each do |room_name, room_data|
        accessor = house_class::ROOM_NAMES[room_name.to_sym] ||
          raise(ArgumentError, "Unknown room: #{room_name}")

        room = house.send(accessor)
        configure_room(room, room_data)
      end

      house
    end

    def configure_room(room, data)
      room.paint_color = data[:paint_color].to_sym if data[:paint_color]

      %i[lamp curio wall_hanging].each do |slot_type|
        next unless data[slot_type]

        slot_data = data[slot_type]
        room.send(slot_type).assign_attributes(
          color: slot_data[:color]&.to_sym,
          style: slot_data[:style]&.to_sym
        )
      end
    end

    def build_players
      (@data[:players] || []).map do |player_data|
        conditions = player_data[:conditions].map do |cond_data|
          Conditions::Declarative.new(definition: cond_data)
        end

        Player.new(conditions: conditions)
      end
    end
  end
end
