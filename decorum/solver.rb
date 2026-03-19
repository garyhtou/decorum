module Decorum
  class Solver
    def initialize(scenario)
      @scenario = scenario
    end

    def run
      @space = SearchSpace.new(@scenario)

      house = @scenario.house.class.new.clear!

      if backtrack(house, 0)
        house.deep_dup
      end
    end

    private

    def backtrack(house, depth)
      if depth == @space.room_order.size
        return @scenario.win?(using_house: house)
      end

      position = @space.room_order[depth]
      triggered = @space.conditions_by_trigger[position]

      @space.domains[position].each do |room_state|
        house.send("#{position}=", room_state)

        next unless triggered.all? { |e| @space.safe_check(e, house) }

        return true if backtrack(house, depth + 1)
      end

      house.send("#{position}=", nil)
      false
    end
  end
end
