module Aviator
  class FlightSimulationService
    TICK_INTERVAL = 0.2.seconds
    INITIAL_MULTIPLIER = 0.01
    INITIAL_ACCELERATION = 1.1  # faster early growth

    def initialize(round)
      @round = round
      @tick_count = 0
    end

    def start!
      return unless @round.flying?

      schedule_tick(0.0)
    end

    def tick!(multiplier)
      round = @round.reload
      return unless round.flying?

      if multiplier >= round.crash_point
        broadcast_crash(round.crash_point)
        round.end_round!
      else
        broadcast_multiplier(multiplier)

        # Schedule next tick safely
        next_tick = next_multiplier(multiplier)
        if next_tick >= round.crash_point
          tick!(round.crash_point) # force final tick immediately
        else
          schedule_tick(next_tick)
        end
      end
    end

    private

    def schedule_tick(multiplier)
      FlightTickJob.set(wait: TICK_INTERVAL).perform_later(@round.id, multiplier)
    end

    def next_multiplier(current)
      @tick_count += 1

      if current.zero? && @tick_count == 1
        INITIAL_MULTIPLIER
      elsif @tick_count <= 5
        current * INITIAL_ACCELERATION
      else
        current * 1.03
      end
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
