module Aviator
  class FlightSimulationService
    TICK_INTERVAL = 0.2.seconds # how often to broadcast new multiplier

    def initialize(round)
      @round = round
    end

    def start!
      return unless @round.flying?

      # Kick off first tick
      schedule_tick(1.0)
    end

    def tick!(multiplier)
      return unless @round.reload.flying?

      if multiplier >= @round.crash_point
        @round.end_round!
        broadcast_crash(multiplier)
      else
        broadcast_multiplier(multiplier)
        schedule_tick(next_multiplier(multiplier))
      end
    end

    private

    def schedule_tick(multiplier)
      FlightTickJob.set(wait: TICK_INTERVAL).perform_later(@round.id, multiplier)
    end

    def next_multiplier(current)
      # simple exponential growth model
      (current * 1.03).round(2) # grows ~3% per tick
    end

    def broadcast_multiplier(multiplier)
      ActionCable.server.broadcast(
        "aviator_round_#{@round.id}",
        { event: "flying", multiplier: multiplier }
      )
    end

    def broadcast_crash(multiplier)
      ActionCable.server.broadcast(
        "aviator_round_#{@round.id}",
        { event: "crashed", multiplier: multiplier }
      )
    end
  end
end
