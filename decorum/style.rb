module Decorum
  class Style
    include ActiveModel::Model

    NAMES = %w[Modern Antique Retro Unusual]
    attr_accessor :name
  end
end
