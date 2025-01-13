module Decorum
  class Color
    include ActiveModel::Model

    NAMES = %w[Red Blue Green Yellow]
    attr_accessor :name

    def warm?
      %w[red yellow].include? name
    end

    def cool?
      %w[green blue].include? name
    end
  end
end
