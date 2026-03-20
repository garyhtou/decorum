module Decorum
  module Conditions
    class Declarative < ::Decorum::Condition
      attr_reader :definition

      def initialize(definition:)
        @definition = definition.deep_symbolize_keys
      end

      def fulfilled?(player:, house:)
        scope = @definition[:scope].to_sym

        if scope.to_s.start_with?("each_room")
          evaluate_each_room(house, scope)
        else
          rooms = resolve_scope(house)
          subjects = resolve_subject(rooms)
          subjects = apply_filter(subjects)
          evaluate_assertion(subjects)
        end
      end

      def ==(other)
        other.is_a?(self.class) && definition == other.definition
      end

      private

      # --- Scope: which rooms to examine ---

      POSITION_SCOPES = {
        house: %i[top_left_room top_right_room bottom_left_room bottom_right_room],
        upstairs: %i[top_left_room top_right_room],
        downstairs: %i[bottom_left_room bottom_right_room],
        left_side: %i[top_left_room bottom_left_room],
        right_side: %i[top_right_room bottom_right_room],
      }.freeze

      # Maps each_room variants to the positions they iterate
      EACH_ROOM_SCOPES = {
        each_room: POSITION_SCOPES[:house],
        each_room_upstairs: POSITION_SCOPES[:upstairs],
        each_room_downstairs: POSITION_SCOPES[:downstairs],
        each_room_left_side: POSITION_SCOPES[:left_side],
        each_room_right_side: POSITION_SCOPES[:right_side],
      }.freeze

      # Room name → position accessor (covers both house types)
      ROOM_NAME_TO_POSITION = {
        bathroom: :top_left_room,
        bedroom: :top_right_room,
        living_room: :bottom_left_room,
        kitchen: :bottom_right_room,
        bedroom_a: :top_left_room,
        bedroom_b: :top_right_room,
      }.freeze

      def resolve_scope(house)
        scope = @definition[:scope].to_sym

        positions = if POSITION_SCOPES.key?(scope)
                      POSITION_SCOPES[scope]
                    elsif house.class.const_defined?(:ROOM_NAMES) && house.class::ROOM_NAMES.key?(scope)
                      [house.class::ROOM_NAMES[scope]]
                    else
                      raise ArgumentError, "Unknown scope: #{scope}"
                    end

        positions.map { |pos| house.send(pos) }.compact
      end

      # Evaluate the condition per-room; all rooms must pass
      def evaluate_each_room(house, scope)
        positions = EACH_ROOM_SCOPES[scope] ||
          raise(ArgumentError, "Unknown each_room scope: #{scope}")

        rooms = positions.map { |pos| house.send(pos) }.compact

        rooms.all? do |room|
          subjects = resolve_subject([room])
          subjects = apply_filter(subjects)
          evaluate_assertion(subjects)
        end
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
        elsif assertion.key?(:covers)
          evaluate_covers(subjects, assertion[:covers])
        elsif assertion.key?(:unique)
          evaluate_unique(subjects, assertion[:unique])
        else
          raise ArgumentError, "Unknown assertion: #{assertion.keys}"
        end
      end

      def evaluate_count(subjects, count_def)
        count = case @definition[:subject].to_sym
                when :lamps, :curios, :wall_hangings
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

      # All listed values must appear among the subjects
      def evaluate_covers(subjects, covers_def)
        values = covers_def[:values].map(&:to_s)
        attribute = covers_def[:attribute]

        present = if attribute
                    subjects.map { |s| s.send(attribute).to_s }
                  else
                    subjects.map(&:to_s)
                  end

        values.all? { |v| present.include?(v) }
      end

      # Distinct values of an attribute must be ≤ max
      def evaluate_unique(subjects, unique_def)
        attribute = unique_def[:attribute]
        max = unique_def[:max]

        distinct = if attribute
                     subjects.map { |s| s.send(attribute) }.uniq
                   else
                     subjects.uniq
                   end

        distinct.size <= max
      end
    end
  end
end
