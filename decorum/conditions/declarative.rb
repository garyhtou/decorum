module Decorum
  module Conditions
    class Declarative < ::Decorum::Condition
      attr_reader :definition

      def initialize(definition:)
        @definition = definition.deep_symbolize_keys
      end

      def fulfilled?(player:, house:)
        if expandable?
          expand(house).all? { |c| c.fulfilled?(player: player, house: house) }
        else
          rooms = resolve_scope(house)
          subjects = resolve_subject(rooms)
          subjects = apply_filter(subjects)
          evaluate_assertion(subjects, rooms:)
        end
      end

      def ==(other)
        other.is_a?(self.class) && definition == other.definition
      end

      def expandable?
        @definition[:scope].to_s.start_with?("each_room")
      end

      def expand(house)
        scope = @definition[:scope].to_sym
        positions = EACH_ROOM_SCOPES[scope] ||
          raise(ArgumentError, "Unknown each_room scope: #{scope}")

        positions.filter_map do |pos|
          room_name = house.class::ROOM_NAMES.key(pos)
          next unless room_name

          self.class.new(definition: @definition.merge(scope: room_name.to_s))
        end
      end

      private

      # --- Scope ---

      EACH_ROOM_SCOPES = {
        each_room: House::ROOMS,
        each_room_upstairs: House::POSITION_GROUPS[:upstairs],
        each_room_downstairs: House::POSITION_GROUPS[:downstairs],
        each_room_left_side: House::POSITION_GROUPS[:left_side],
        each_room_right_side: House::POSITION_GROUPS[:right_side],
      }.freeze

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

      # --- Subject ---

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
          rooms.map(&:paint_color) + rooms.flat_map(&:objects).map(&:color)
        else
          raise ArgumentError, "Unknown subject: #{@definition[:subject]}"
        end
      end

      # --- Filter ---

      def apply_filter(subjects)
        return subjects unless @definition[:filter]

        filter = @definition[:filter]
        subjects.select do |subject|
          filter.all? { |attr, value| subject.respond_to?(attr) && subject.send(attr).to_s == value.to_s }
        end
      end

      # --- Assertion ---

      def evaluate_assertion(subjects, rooms: [])
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
        elsif assertion.key?(:all_unique)
          extract_values(subjects, assertion[:all_unique][:attribute]).then { |v| v.size == v.uniq.size }
        elsif assertion.key?(:matches_paint)
          evaluate_matches_paint(subjects, assertion[:matches_paint], rooms)
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

      def evaluate_covers(subjects, covers_def)
        present = extract_values(subjects, covers_def[:attribute]).map(&:to_s)
        covers_def[:values].all? { |v| present.include?(v.to_s) }
      end

      def evaluate_unique(subjects, unique_def)
        extract_values(subjects, unique_def[:attribute]).uniq.size <= unique_def[:max]
      end

      def evaluate_matches_paint(subjects, matches_paint_def, rooms)
        return false if rooms.empty? || subjects.empty?

        paint_colors = rooms.map(&:paint_color)
        extract_values(subjects, matches_paint_def[:attribute]).any? { |v| paint_colors.include?(v) }
      end

      # Extract attribute values from subjects, or use subjects directly
      def extract_values(subjects, attribute)
        attribute ? subjects.map { |s| s.send(attribute) } : subjects
      end
    end
  end
end
