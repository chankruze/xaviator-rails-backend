class EndAviatorRoundJob < ApplicationJob
  queue_as :default

  def perform(round_id)
    round = AviatorRound.find_by(id: round_id)
    return unless round&.flying?

    round.end_round!

    ActionCable.server.broadcast("aviator_rounds", { id: round.id, event: "crashed", multiplier: round.crash_point })

    Rails.logger.warn("Failsafe ended AviatorRound #{round.id}")
  rescue => e
    Rails.logger.error("EndAviatorRoundJob failed: #{e.message}")
  end
end
