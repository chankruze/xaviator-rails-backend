class EndAviatorRoundJob < ApplicationJob
  queue_as :default

  def perform(round_id)
    round = AviatorRound.find_by(id: round_id)
    return unless round&.flying?

    round.end_round!

    Rails.logger.info("AviatorRound #{round.id} ended successfully!")
  rescue => e
    Rails.logger.error("EndAviatorRoundJob failed: #{e.message}")
  end
end
