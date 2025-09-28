class CleanupEndedRoundsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    # Find rounds that are ended (crashed)
    ended_rounds = AviatorRound.where(status: :crashed)

    # Delete them (or you can archive/move to another table if needed)
    deleted_count = ended_rounds.delete_all

    Rails.logger.info "[CleanupEndedRoundsJob] Deleted #{deleted_count} ended rounds"
  end
end
