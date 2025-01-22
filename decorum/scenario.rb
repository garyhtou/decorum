module Decorum
  class Scenario
    include ActiveModel::Model

    PLAYERS = %i[player_one player_two player_three player_four].freeze
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

    def ==(other)
      [:class, *PLAYERS, :house].all? do |attr|
        self.send(attr) == other.send(attr)
      end
    end

    alias_method :eql?, :==

    def initialize_dup(source)
      [*PLAYERS, :house].each do |attr|
        self.send("#{attr}=", source.send(attr).deep_dup)
      end

      super
    end

    def to_s
      house.to_s
    end

  end
end
