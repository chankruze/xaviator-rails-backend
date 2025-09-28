class FlightTickJob < ApplicationJob
  queue_as :default

  def perform(*args)
    round = AviatorRound.find_by(id: round_id)
    return unless round&.flying?

    Aviator::FlightSimulationService.new(round).tick!(multiplier)
  rescue => e
    Rails.logger.error("FlightTickJob failed: #{e.message}")
  end
end
