module Decorum
  class Scenario
    include ActiveModel::Model

    attr_accessor :player_one
    attr_accessor :player_two
    attr_accessor :player_three
    attr_accessor :player_four

    attr_accessor :house

    def self.setup
      raise NotImplementedError, "This method should instantiate a new scenario with the appropriate players and house."
    end

    def players
      [player_one, player_two, player_three, player_four].compact
    end

    def num_players
      players.length
    end

    def conditions
      players.to_h do |player|
        [player, player.conditions]
      end
    end

    def win?
      players.all? do |player|
        player.fulfilled?(house:)
      end
    end

  end
end
