require "active_model"
require "active_support/all"
require "rainbow"

module Decorum
  COLORS = %i[red blue green yellow]
end

# House must load before conditions/declarative.rb which references House constants
require_relative "decorum/house"

Dir.glob("decorum/**/*.rb").each do |file|
  require_relative file
end
