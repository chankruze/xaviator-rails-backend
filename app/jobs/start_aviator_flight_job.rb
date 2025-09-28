class StartAviatorFlightJob < ApplicationJob
  queue_as :default

  def perform(round_id)
    round = AviatorRound.find_by(id: round_id)
    return unless round&.betting?

    # Start the flight
    round.start_flight!

    # End the round after simulation duration to reach the crash point
    Aviator::FlightSimulationService.new(round).start!

    # Schedule a failsafe to force-crash if something goes wrong
    # EndAviatorRoundJob.set(wait: 120.seconds).perform_later(round.id)

    Rails.logger.info("AviatorRound #{round.id} flight simulation started successfully!")
  rescue => e
    Rails.logger.error("StartAviatorFlightJob failed: #{e.message}")
  end
end
