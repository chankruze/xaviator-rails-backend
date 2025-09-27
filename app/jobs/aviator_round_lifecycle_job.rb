class AviatorRoundLifecycleJob < ApplicationJob
  queue_as :default

  def perform(*args)
    round = AviatorRound.create!
    round.start_betting!

    # Schedule flight start after betting_duration
    StartAviatorFlightJob.set(wait: round.betting_duration.seconds).perform_later(round.id)
    # StartAviatorFlightJob.perform_later(round.id, wait_until: round.betting_ends_at)

    Rails.logger.info("AviatorRound #{round.id} created and started betting phase")
  rescue => e
    Rails.logger.error("AviatorRoundLifecycleJob failed: #{e.message}")
  end
end
