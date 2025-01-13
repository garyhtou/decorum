module Decorum
  class Scenario
    include ActiveModel::Model

    attr_accessor :player_one
    attr_accessor :player_two
    attr_accessor :player_three
    attr_accessor :player_four

    attr_accessor :house

    def players
      [player_one, player_two, player_three, player_four].compact
    end

    def num_players
      players.length
    end

    def win?
      players.all?(&:fulfilled?)
    end

  end
end
