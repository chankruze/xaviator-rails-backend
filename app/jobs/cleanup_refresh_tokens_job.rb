class CleanupRefreshTokensJob < ApplicationJob
  queue_as :background

  def perform(*args)
    # Revoke expired tokens (that haven’t been revoked yet)
    RefreshToken.where("expires_at < ?", Time.current)
                .where(revoked_at: nil)
                .find_each(batch_size: 100) do |token|
      token.revoke!
    end

    # Delete revoked tokens older than 7 days
    RefreshToken.where("revoked_at < ?", 7.days.ago).delete_all
  end
end
