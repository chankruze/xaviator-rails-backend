class AviatorRound < ApplicationRecord
  # Status Machine
  enum status: { waiting: 0, betting: 1, flying: 2, crashed: 3 }

  # Validations
  validates :crash_point, numericality: { greater_than: 1.0 }, allow_nil: true
  validates :betting_duration, numericality: { only_integer: true, greater_than: 0 }
  validates :house_edge, numericality: { greater_than_or_equal_to: 0, less_than: 0.5 } # Max 50% edge
  validates :max_multiplier, numericality: { greater_than: 1.0 }

  # Callbacks
  before_create :set_default_timestamps
  after_update :check_for_betting_phase_end, if: :saved_change_to_status?

  # Associations
  # has_many :bets, dependent: :destroy
  # has_many :cashouts, through: :bets

  # Instance Methods
  def start_betting!
    update!(
      status: :betting,
      started_at: Time.current,
      betting_ends_at: Time.current + betting_duration.seconds
    )
    # TODO Place fake bets
    # GenerateFakeBetsJob.perform_later(id)
  end

  def start_flight!
    return if crashed? || flying?

    # Calculate crash point using house edge algorithm
    update!(
      status: :flying,
      crash_point: calculate_crash_point
    )

    # TODO: Broadcast the flight data points for frontend
    # FlightSimulationJob.perform_later(id)
  end

  def end_round!
    return if crashed?
    update!(status: :crashed, crashed_at: Time.current)
    # TODO: Process payouts
    # PayoutWinnersJob.perform_later(id)
  end

  private

  def set_default_timestamps
    self.started_at ||= Time.current
  end

  def check_for_betting_phase_end
    return unless betting? && betting_ends_at.past?
    start_flight!
  end

  # Cryptographically fair crash point calculation
  def calculate_crash_point
    # Using provably fair algorithm (simplified example)
    hash = Digest::SHA256.hexdigest("#{id}#{started_at.to_i}")
    h = hash[0..7].to_i(16)
    e = 2**32
    point = (e / (h + 1)) * (1 - house_edge)
    [ point.floor(2), max_multiplier ].min
  end
end
