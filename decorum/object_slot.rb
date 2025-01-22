module Decorum
  class ObjectSlot
    include ActiveModel::Model
    include HumanizedName
    include GeneratableChoices

    TYPES = %i[lamp curio wall_hanging]
    attr_accessor :type
    validates :type, presence: true, inclusion: { in: TYPES }

    attr_accessor :color
    validates :color, inclusion: { in: ::Decorum::COLORS }

    STYLES = %i[modern antique retro unusual]
    attr_accessor :style
    validates :style, inclusion: { in: STYLES }

    humanized_name_for :type, :color, :style

    COMBINATIONS = {
      wall_hanging: [
        { color: :red, style: :modern },
        { color: :green, style: :antique },
        { color: :blue, style: :retro },
        { color: :yellow, style: :unusual }
      ],
      curio: [
        { color: :green, style: :modern },
        { color: :blue, style: :antique },
        { color: :yellow, style: :retro },
        { color: :red, style: :unusual }
      ],
      lamp: [
        { color: :blue, style: :modern },
        { color: :yellow, style: :antique },
        { color: :red, style: :retro },
        { color: :green, style: :unusual }
      ]
    }

    validate do
      errors.add(:base, "Invalid color/style combination for #{humanized_type}") unless valid_combination?
    end

    def empty? = color.nil? && style.nil?

    def filled? = !empty?

    def warm_color?
      %i[red yellow].include? name
    end

    def cool_color?
      %i[green blue].include? name
    end

    def possible_choices
      # Allows for removing, adding, or replacing object of the same type
      generate_choices(COMBINATIONS[type])
    end

    def description
      return "empty #{humanized_type}" if empty?

      "#{color} #{style} #{humanized_type}"
    end

    def ==(other)
      [:class, :type, :color, :style].all? do |attr|
        self.send(attr) == other.send(attr)
      end
    end

    alias_method :eql?, :==

    def to_s
      value = filled? ? Rainbow(style.to_s.first.upcase).send(color) : " "
      Display.template(type, value)
    end

    private def valid_combination?
      return true if empty?

      COMBINATIONS[type].include?({ color:, style: })
    end
  end
end
