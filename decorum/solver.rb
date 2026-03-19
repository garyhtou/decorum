require "set"

module Decorum
  class Solver
    def initialize(scenario)
      @scenario = scenario
    end

    def run
      precompute_object_pool
      precompute_domains
      detect_all_required_rooms
      apply_unary_filters
      determine_room_order
      setup_condition_triggers

      house = @scenario.house.class.new
      House::ROOMS.each { |r| house.send("#{r}=", nil) }

      if backtrack(house, 0)
        house.deep_dup
      end
    end

    private

    # Create 15 shared ObjectSlot instances: 3 types × (1 empty + 4 filled)
    def precompute_object_pool
      @object_pool = {}
      ObjectSlot::TYPES.each do |type|
        slots = [ObjectSlot.new(type: type)] # empty
        ObjectSlot::COMBINATIONS[type].each do |combo|
          slots << ObjectSlot.new(type: type, **combo)
        end
        @object_pool[type] = slots.freeze
      end
    end

    # Generate all 500 valid Room states per position
    def precompute_domains
      @domains = {}
      House::ROOMS.each do |position|
        template = @scenario.house.send(position)
        next unless template

        states = []
        Decorum::COLORS.each do |paint|
          @object_pool[:lamp].each do |lamp|
            @object_pool[:curio].each do |curio|
              @object_pool[:wall_hanging].each do |wh|
                states << Room.new(
                  name: template.name,
                  paint_color: paint,
                  lamp: lamp,
                  curio: curio,
                  wall_hanging: wh,
                  object_order: template.object_order.dup
                )
              end
            end
          end
        end

        @domains[position] = states
      end
    end

    # Collect all conditions paired with their player, and auto-detect required rooms
    def detect_all_required_rooms
      @condition_entries = @scenario.players.flat_map do |player|
        player.conditions.map do |condition|
          {
            condition: condition,
            player: player,
            required_rooms: detect_required_rooms(condition, player)
          }
        end
      end
    end

    # Probe a condition to discover which room accessors it calls
    def detect_required_rooms(condition, player)
      probe_house = @scenario.house.deep_dup
      accessed = Set.new

      House::ROOMS.each do |room_sym|
        original_room = probe_house.send(room_sym)
        probe_house.define_singleton_method(room_sym) do
          accessed << room_sym
          original_room
        end
      end

      condition.fulfilled?(player: player, house: probe_house)
      accessed.to_a
    rescue
      # If probing fails, conservatively assume all rooms are needed
      House::ROOMS.dup
    end

    # Filter domains using conditions that depend on a single room
    def apply_unary_filters
      @condition_entries.each do |entry|
        required = entry[:required_rooms]
        next unless required.size == 1

        position = required.first
        next unless @domains.key?(position)

        dummy_house = @scenario.house.class.new
        House::ROOMS.each { |r| dummy_house.send("#{r}=", nil) }

        @domains[position].select! do |room_state|
          dummy_house.send("#{position}=", room_state)
          entry[:condition].fulfilled?(player: entry[:player], house: dummy_house)
        end
      end
    end

    # Order rooms: smallest filtered domain first, break ties by condition count desc
    def determine_room_order
      active_positions = House::ROOMS.select { |r| @domains.key?(r) }

      condition_count = Hash.new(0)
      @condition_entries.each do |entry|
        entry[:required_rooms].each { |pos| condition_count[pos] += 1 }
      end

      @room_order = active_positions.sort_by do |pos|
        [@domains[pos].size, -condition_count[pos]]
      end
    end

    # Group conditions by the depth at which they become fully checkable
    def setup_condition_triggers
      order_index = @room_order.each_with_index.to_h

      @conditions_by_trigger = Hash.new { |h, k| h[k] = [] }

      @condition_entries.each do |entry|
        required = entry[:required_rooms]
        active_required = required.select { |r| order_index.key?(r) }
        next if active_required.empty?

        # Trigger when the last required room in assignment order is assigned
        trigger = active_required.max_by { |r| order_index[r] }
        @conditions_by_trigger[trigger] << entry
      end
    end

    def backtrack(house, depth)
      if depth == @room_order.size
        # Final safety check: verify ALL conditions via scenario
        return @scenario.win?(using_house: house)
      end

      position = @room_order[depth]
      triggered = @conditions_by_trigger[position]

      @domains[position].each do |room_state|
        house.send("#{position}=", room_state)

        next unless triggered.all? { |e| safe_check(e, house) }

        return true if backtrack(house, depth + 1)
      end

      house.send("#{position}=", nil)
      false
    end

    # Check a condition, rescuing NoMethodError from nil room access
    # (handles imperfect room detection due to short-circuit evaluation)
    def safe_check(entry, house)
      entry[:condition].fulfilled?(player: entry[:player], house: house)
    rescue NoMethodError
      true # can't evaluate yet, don't prune
    end
  end
end
