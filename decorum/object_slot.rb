module Decorum
  class ObjectSlot
    include ActiveModel::Model

    TYPES = %i[lamp, curio, wall_hanging]
    attr_accessor :type
    validates :type, presence: true, inclusion: { in: TYPES }

    attr_accessor :color
    validates :color, inclusion: { in: ::Decorum::COLORS }

    STYLES = %i[modern antique retro unusual]
    attr_accessor :style
    validates :style, inclusion: { in: STYLES }

    def empty? = color.nil? && style.nil?

    def filled? = !empty?

    def warm_color?
      %i[red yellow].include? name
    end

    def cool_color?
      %i[green blue].include? name
    end

    def to_s
      value = filled? ? Rainbow(style.to_s.first.upcase).send(color) : " "
      Display.template(type, value)
    end
  end
end
