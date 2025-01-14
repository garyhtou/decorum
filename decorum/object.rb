module Decorum
  class Object
    include ActiveModel::Model

    TYPES = %i[lamp, curio, wall_hanging]
    attr_accessor :type
    validates :type, presence: true, inclusion: { in: TYPES }

    attr_accessor :color
    validates :color, inclusion: { in: ::Decorum::COLORS }

    STYLES = %i[modern antique retro unusual]
    attr_accessor :style
    validates :style, inclusion: { in: STYLES }

    def warm_color?
      %i[red yellow].include? name
    end

    def cool_color?
      %i[green blue].include? name
    end
  end
end
