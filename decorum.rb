require "active_model"
require "active_support/all"

Dir.glob("decorum/*.rb").each do |file|
  require_relative file
end

module Decorum

end
