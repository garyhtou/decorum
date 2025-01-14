require "active_model"
require "active_support/all"
require "rainbow"

module Decorum
  COLORS = %i[red blue green yellow]

end

Dir.glob("decorum/**/*.rb").each do |file|
  require_relative file
end
