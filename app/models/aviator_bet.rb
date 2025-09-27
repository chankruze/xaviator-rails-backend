class AviatorBet < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :aviator_round

  # Validations
  validates :amount, numericality: { greater_than: 0 }
  validates :user_id, presence: true
  validates :aviator_round_id, presence: true
  validates :user_id, uniqueness: { scope: :aviator_round_id, message: "has already placed a bet on this round" }

  enum :status, { pending: 0, won: 1, lost: 2 }, default: :pending

  # Callbacks
  before_create :set_initial_attributes

  private

  def set_initial_attributes
    self.status ||= :pending
  end
end
