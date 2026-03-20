module Decorum
  module Conditions
    class Declarative < ::Decorum::Condition
      attr_reader :definition

      def initialize(definition:)
        @definition = definition.deep_symbolize_keys
      end

      def fulfilled?(player:, house:)
        rooms = resolve_scope(house)
        subjects = resolve_subject(rooms)
        subjects = apply_filter(subjects)
        evaluate_assertion(subjects)
      end

      def ==(other)
        other.is_a?(self.class) && definition == other.definition
      end

      private

      # --- Scope: which rooms to examine ---

      def resolve_scope(house)
        scope = @definition[:scope].to_sym

        positions = if scope == :house
                      House::ROOMS
                    elsif House::POSITION_GROUPS.key?(scope)
                      House::POSITION_GROUPS[scope]
                    elsif house.class.const_defined?(:ROOM_NAMES) && house.class::ROOM_NAMES.key?(scope)
                      [house.class::ROOM_NAMES[scope]]
                    else
                      raise ArgumentError, "Unknown scope: #{scope}"
                    end

        positions.map { |pos| house.send(pos) }.compact
      end

      # --- Subject: what values to extract from the rooms ---

      SLOT_TYPES = { lamps: :lamp, curios: :curio, wall_hangings: :wall_hanging }.freeze

      def resolve_subject(rooms)
        case @definition[:subject].to_sym
        when :paint_color
          rooms.map(&:paint_color)
        when :objects
          rooms.flat_map(&:objects)
        when :lamps, :curios, :wall_hangings
          slot_type = SLOT_TYPES[@definition[:subject].to_sym]
          rooms.map { |r| r.send(slot_type) }
        when :object_slots
          rooms.flat_map(&:object_slots)
        when :empty_slots
          rooms.flat_map { |r| r.object_slots.select(&:empty?) }
        when :features
          # Both paint colors and object colors
          colors = rooms.map(&:paint_color)
          object_colors = rooms.flat_map(&:objects).map(&:color)
          colors + object_colors
        else
          raise ArgumentError, "Unknown subject: #{@definition[:subject]}"
        end
      end

      # --- Filter: narrow subjects by attribute matches ---

      def apply_filter(subjects)
        return subjects unless @definition[:filter]

        filter = @definition[:filter]

        subjects.select do |subject|
          filter.all? do |attr, value|
            subject.respond_to?(attr) && subject.send(attr).to_s == value.to_s
          end
        end
      end

      # --- Assertion: evaluate the final predicate ---

      def evaluate_assertion(subjects)
        assertion = @definition[:assertion]

        if assertion.key?(:count)
          evaluate_count(subjects, assertion[:count])
        elsif assertion.key?(:equals)
          subjects.all? { |s| s.to_s == assertion[:equals].to_s }
        elsif assertion.key?(:not_equals)
          subjects.none? { |s| s.to_s == assertion[:not_equals].to_s }
        elsif assertion.key?(:includes)
          subjects.any? { |s| s.to_s == assertion[:includes].to_s }
        elsif assertion.key?(:excludes)
          subjects.none? { |s| s.to_s == assertion[:excludes].to_s }
        else
          raise ArgumentError, "Unknown assertion: #{assertion.keys}"
        end
      end

      def evaluate_count(subjects, count_def)
        count = case @definition[:subject].to_sym
                when :lamps, :curios, :wall_hangings
                  # For specific slot types, count filled slots
                  subjects.count(&:filled?)
                else
                  subjects.size
                end

        valid = true
        valid &&= count >= count_def[:min] if count_def[:min]
        valid &&= count <= count_def[:max] if count_def[:max]
        valid &&= count == count_def[:equals] if count_def[:equals]
        valid
      end
    end
  end
end
