module Decorum
  class DifficultyAnalyzer
    DEFAULT_SOLUTION_CAP = 10_000

    def initialize(scenario, solution_cap: DEFAULT_SOLUTION_CAP)
      @scenario = scenario
      @solution_cap = solution_cap
    end

    def analyze
      @space = SearchSpace.new(@scenario)
      find_all_solutions

      {
        solution_count: @solution_count,
        solution_count_capped: @solution_count >= @solution_cap,
        min_moves: @move_distances.min,
        avg_moves: @move_distances.empty? ? nil : (@move_distances.sum.to_f / @move_distances.size).round(1),
        max_moves: @move_distances.max,
        constraint_tightness: compute_constraint_tightness,
        condition_count: compute_condition_count,
        condition_locality: compute_condition_locality,
        conflict_density: compute_conflict_density,
        difficulty_score: compute_difficulty_score(@solution_count, @move_distances)
      }
    end

    private

    # --- Search (exhaustive, capped) ---

    def find_all_solutions
      house = @scenario.house.class.new.clear!
      @solution_count = 0
      @move_distances = []
      backtrack_all(house, 0)
    end

    def backtrack_all(house, depth)
      return if @solution_count >= @solution_cap

      if depth == @space.room_order.size
        if @scenario.win?(using_house: house)
          @solution_count += 1
          @move_distances << move_distance(house)
        end
        return
      end

      position = @space.room_order[depth]
      triggered = @space.conditions_by_trigger[position]

      @space.domains[position].each do |room_state|
        break if @solution_count >= @solution_cap

        house.send("#{position}=", room_state)

        next unless triggered.all? { |e| @space.safe_check(e, house) }

        backtrack_all(house, depth + 1)
      end

      house.send("#{position}=", nil)
    end

    # --- Move distance ---

    def move_distance(solution_house)
      initial = @scenario.house
      distance = 0

      House::ROOMS.each do |room_sym|
        initial_room = initial.send(room_sym)
        solution_room = solution_house.send(room_sym)
        next unless initial_room && solution_room

        distance += 1 if initial_room.paint_color != solution_room.paint_color

        Room::OBJECTS.each do |obj_type|
          distance += 1 if initial_room.send(obj_type) != solution_room.send(obj_type)
        end
      end

      distance
    end

    # --- Metrics ---

    def compute_constraint_tightness
      @space.room_order.to_h do |position|
        total = @space.unfiltered_domain_sizes[position]
        filtered = @space.domains[position].size
        [position, { filtered: filtered, total: total, ratio: (filtered.to_f / total).round(4) }]
      end
    end

    def compute_condition_count
      per_player = @scenario.players.map { |p| p.conditions.size }
      { total: per_player.sum, per_player: per_player }
    end

    def compute_condition_locality
      counts = { single_room: 0, two_room: 0, house_wide: 0 }

      @space.condition_entries.each do |entry|
        case entry[:required_rooms].size
        when 1 then counts[:single_room] += 1
        when 2 then counts[:two_room] += 1
        else counts[:house_wide] += 1
        end
      end

      counts
    end

    def compute_conflict_density
      density = Hash.new(0)

      @space.condition_entries.each do |entry|
        entry[:required_rooms].each { |pos| density[pos] += 1 }
      end

      @space.room_order.to_h { |pos| [pos, density[pos]] }
    end

    def compute_difficulty_score(solution_count, move_distances)
      return 1.0 if solution_count == 0

      # Solution scarcity: fewer solutions = harder (log scale)
      max_solutions = 500**4.0
      scarcity = 1.0 - (Math.log(solution_count + 1) / Math.log(max_solutions + 1))

      # Minimum moves normalized to max possible (16)
      min_moves = move_distances.min || 0
      moves_factor = min_moves / 16.0

      # Condition count normalized (typical range: 3-10)
      conditions_factor = [@space.condition_entries.size / 10.0, 1.0].min

      # House-wide condition ratio
      locality = compute_condition_locality
      total_conditions = @space.condition_entries.size.to_f
      house_wide_ratio = total_conditions > 0 ? locality[:house_wide] / total_conditions : 0.0

      # Average conflict density normalized
      density = compute_conflict_density
      avg_density = density.values.sum.to_f / [density.size, 1].max
      max_density = total_conditions
      density_factor = max_density > 0 ? avg_density / max_density : 0.0

      score = (
        scarcity * 0.30 +
        moves_factor * 0.25 +
        conditions_factor * 0.20 +
        house_wide_ratio * 0.15 +
        density_factor * 0.10
      )

      score.clamp(0.0, 1.0).round(4)
    end
  end
end
