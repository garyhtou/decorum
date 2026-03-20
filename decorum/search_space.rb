require "set"

module Decorum
  class SearchSpace
    attr_reader :scenario, :domains, :room_order, :conditions_by_trigger,
                :condition_entries, :unfiltered_domain_sizes

    def initialize(scenario)
      @scenario = scenario
      prepare
    end

    # Check a condition, rescuing NoMethodError from nil room access
    # (handles imperfect room detection due to short-circuit evaluation)
    def safe_check(entry, house)
      entry[:condition].fulfilled?(player: entry[:player], house: house)
    rescue NoMethodError
      true
    end

    private

    def prepare
      precompute_object_pool
      precompute_domains
      detect_all_required_rooms
      @unfiltered_domain_sizes = @domains.transform_values(&:size)
      apply_unary_filters
      determine_room_order
      setup_condition_triggers
    end

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

    # Collect all conditions paired with their player, and auto-detect required rooms.
    # Expandable conditions (e.g., each_room) are split into per-room conditions
    # with a shared group ID for UI grouping.
    def detect_all_required_rooms
      group_counter = 0

      @condition_entries = @scenario.players.flat_map do |player|
        player.conditions.flat_map do |condition|
          if condition.respond_to?(:expandable?) && condition.expandable?
            group_id = "group_#{group_counter}"
            group_counter += 1

            condition.expand(@scenario.house).map do |expanded|
              {
                condition: expanded,
                player: player,
                required_rooms: detect_required_rooms(expanded, player),
                group: group_id,
                source_definition: condition.definition,
              }
            end
          else
            [{
              condition: condition,
              player: player,
              required_rooms: detect_required_rooms(condition, player),
              group: nil,
              source_definition: nil,
            }]
          end
        end
      end
    end

    # Probe a condition to discover which room accessors it calls.
    # Runs multiple probes with different house states to handle short-circuit
    # evaluation (e.g., `a && b` skips b when a is false).
    def detect_required_rooms(condition, player)
      accessed = Set.new

      probe_houses.each do |probe_house|
        House::ROOMS.each do |room_sym|
          original_room = probe_house.send(room_sym)
          probe_house.define_singleton_method(room_sym) do
            accessed << room_sym
            original_room
          end
        end

        condition.fulfilled?(player: player, house: probe_house) rescue nil
      end

      accessed.empty? ? House::ROOMS.dup : accessed.to_a
    rescue
      House::ROOMS.dup
    end

    # Build probe houses with varied states to maximize branch coverage
    def probe_houses
      houses = [@scenario.house.deep_dup]

      alt = @scenario.house.deep_dup
      House::ROOMS.each do |room_sym|
        room = alt.send(room_sym)
        next unless room

        room.paint_color = (Decorum::COLORS - [room.paint_color]).first
        Room::OBJECTS.each do |obj_type|
          slot = room.send(obj_type)
          if slot.empty?
            slot.assign_attributes(ObjectSlot::COMBINATIONS[obj_type].first)
          else
            slot.assign_attributes(color: nil, style: nil)
          end
        end
      end
      houses << alt

      houses
    end

    # Filter domains using conditions that depend on a single room
    def apply_unary_filters
      @condition_entries.each do |entry|
        required = entry[:required_rooms]
        next unless required.size == 1

        position = required.first
        next unless @domains.key?(position)

        dummy_house = @scenario.house.class.new.clear!

        @domains[position].select! do |room_state|
          dummy_house.send("#{position}=", room_state)
          begin
            entry[:condition].fulfilled?(player: entry[:player], house: dummy_house)
          rescue NoMethodError
            true
          end
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

        trigger = active_required.max_by { |r| order_index[r] }
        @conditions_by_trigger[trigger] << entry
      end
    end
  end
end
