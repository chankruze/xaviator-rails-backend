class AviatorRound < ApplicationRecord
  # Constants
  DEFAULT_BETTING_DURATION = 30 # seconds
  MIN_BETTING_DURATION = 10
  MAX_BETTING_DURATION = 60

  MIN_HOUSE_EDGE = 0.1
  MAX_HOUSE_EDGE = 0.5

  MIN_MAX_MULTIPLIER = 1.01
  MAX_MAX_MULTIPLIER = 50.0
  DEFAULT_MAX_MULTIPLIER = 10.4

  # Status Machine
  enum :status, { waiting: 0, betting: 1, flying: 2, crashed: 3 }, default: :waiting

  # Validations
  validates :crash_point, numericality: { greater_than: 1.0 }, if: -> { flying? || crashed? }, allow_nil: true
  validates :betting_duration, numericality: { only_integer: true, greater_than_or_equal_to: MIN_BETTING_DURATION, less_than_or_equal_to: MAX_BETTING_DURATION }
  validates :house_edge, numericality: { greater_than_or_equal_to: MIN_HOUSE_EDGE, less_than: MAX_HOUSE_EDGE } # Max 50% edge
  validates :max_multiplier, numericality: { greater_than: MIN_MAX_MULTIPLIER }
  # TODO: validate max bet limit and min bet limit if added (e.g., max 1000, min 1 to start)

  # Callbacks
  before_validation :set_default_attributes
  after_update :check_for_betting_phase_end, if: :saved_change_to_status?

  # Associations
  has_many :bets, class_name: "AviatorBet", dependent: :destroy
  has_many :users, through: :bets
  # has_many :cashouts, through: :bets

  # Instance Methods
  def start_betting!
    update!(
      status: :betting,
      betting_started_at: Time.current,
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

  def set_default_attributes
    self.betting_duration ||= DEFAULT_BETTING_DURATION
    self.house_edge ||= rand(MIN_HOUSE_EDGE..MAX_HOUSE_EDGE).round(4)
    self.max_multiplier ||= random_max_multiplier
  end

  def check_for_betting_phase_end
    return unless betting? && betting_ends_at.past?
    start_flight!
  end

  def calculate_crash_point
    # --- Provably fair hash-based seed ---
    seed = "#{id}-#{betting_started_at.to_i}"
    hash = Digest::SHA256.hexdigest(seed)
    h    = hash[0..7].to_i(16)              # take first 32 bits
    random = h.to_f / 0xFFFFFFFF            # normalize to [0,1)

    # --- Skewed crash formula (like Crash games) ---
    # house_edge controls the average crash
    crash = MIN_MAX_MULTIPLIER + (max_multiplier - MIN_MAX_MULTIPLIER) * (1 - random**(1.0 / (1 - house_edge)))

    crash.clamp(MIN_MAX_MULTIPLIER, max_multiplier).round(2)
  end


  def random_max_multiplier
    probability_high = rand(0.03..0.08)

    if rand < probability_high
      # Rarely generate in upper range
      range = MAX_MAX_MULTIPLIER - DEFAULT_MAX_MULTIPLIER
      base = rand * range + DEFAULT_MAX_MULTIPLIER
    else
      # Mostly in lower range, skewed by sqrt
      range = DEFAULT_MAX_MULTIPLIER - MIN_MAX_MULTIPLIER
      base = Math.sqrt(rand) * range + MIN_MAX_MULTIPLIER
    end

    base.round(2)
  end
end
