class StartAviatorFlightJob < ApplicationJob
  queue_as :default

  def perform(round_id)
    round = AviatorRound.find_by(id: round_id)
    return unless round&.betting?

    # Start the flight
    round.start_flight!

    # TODO: End the round after simulation duration to reach the crash point
    EndAviatorRoundJob.perform_later(round.id)

    Rails.logger.info("AviatorRound #{round.id} flight started successfully!")
  rescue => e
    Rails.logger.error("StartAviatorFlightJob failed: #{e.message}")
  end
end
