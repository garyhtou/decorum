module Decorum
  module Scenarios
    class WelcomeHome < Scenario
      def self.setup
        house = House::TwoPlayer.new
        house.bathroom.tap do |room|
          room.wall_color = :blue
          room.curio = Decorum::Object.new(type: :curio, style: :antique, color: :blue)
          room.wall_hanging = ::Decorum::Object.new(type: :wall_hanging, style: :modern, color: :red)
        end
        house.bedroom.tap do |room|
          room.wall_color = :green
          room.lamp = Decorum::Object.new(type: :lamp, style: :unique, color: :green)
        end
        house.living_room.tap do |room|
          room.wall_color = :yellow
          room.lamp = Decorum::Object.new(type: :lamp, style: :retro, color: :red)
        end
        house.kitchen.tap do |room|
          room.wall_color = :red
          room.wall_hanging = Decorum::Object.new(type: :wall_hanging, style: :unique, color: :yellow)
        end

        new(
          house:,
          player_one: Player.new(conditions: [
            Conditions::LeftNoLamps.new,
            Conditions::MaxOneAntique.new,
            Conditions::DownstairsMinTwoObjects.new
          ]),
          player_two: Player.new(conditions: [
            Conditions::LeftPaintedBlue.new,
            Conditions::MinOneAntiqueYellowLamp.new,
            Conditions::KitchenNoObjects.new
          ]),
        )
      end

      def self.solution
        House::TwoPlayer.new.tap do |house|
          house.bathroom.tap do |room|
            room.wall_color = :blue
            room.curio = Decorum::Object.new(type: :curio, style: :retro, color: :yellow)
            room.wall_hanging = ::Decorum::Object.new(type: :wall_hanging, style: :modern, color: :red)
          end
          house.bedroom.tap do |room|
            room.wall_color = :green
            room.lamp = Decorum::Object.new(type: :lamp, style: :antique, color: :yellow)
          end
          house.living_room.tap do |room|
            room.wall_color = :blue
            room.curio = Decorum::Object.new(type: :curio, style: :unusual, color: :red)
            room.wall_hanging = Decorum::Object.new(type: :wall_hanging, style: :retro, color: :blue)
          end
          house.kitchen.tap do |room|
            room.wall_color = :red
          end
        end
      end
    end
  end
end
