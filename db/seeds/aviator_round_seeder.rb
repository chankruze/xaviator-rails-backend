class AviatorRoundSeeder
  def initialize(record_count: 5000, clean: true, cleanup_after: true)
    @record_count       = record_count
    @multiplier_values  = []
    @crash_values       = []
    @clean              = clean
    @cleanup_after      = cleanup_after
  end

  def run
    puts "Seeding #{@record_count} AviatorRounds..."

    cleanup_db("before") if @clean

    @record_count.times do
      round = AviatorRound.create!(
        status: :waiting,
        betting_started_at: Time.current,
        betting_ends_at:    Time.current + rand(10..60).seconds
      )

      # Simulate round lifecycle so crash_point gets generated
      round.start_betting!
      round.start_flight!
      round.end_round!

      @multiplier_values << round.max_multiplier
      @crash_values      << round.crash_point
    end

    print_stats

    cleanup_db("after") if @cleanup_after
  end

  private

  def cleanup_db(phase)
    puts "Cleaning up AviatorRounds table (#{phase})..."
    AviatorRound.delete_all
  end

  def print_stats
    print_distribution_stats("Max Multiplier", @multiplier_values, AviatorRound::DEFAULT_MAX_MULTIPLIER)
    print_distribution_stats("Crash Point",    @crash_values,      AviatorRound::DEFAULT_MAX_MULTIPLIER)
  end

  def print_distribution_stats(label, values, threshold)
    sorted = values.compact.sort
    total  = sorted.size
    return if total.zero?

    count_low  = sorted.count { |v| v < threshold }
    count_high = total - count_low

    mean   = (values.sum / total).round(2)
    median = sorted[total / 2]
    min_v  = sorted.first
    max_v  = sorted.last

    metric_width = 50
    value_width  = 12
    percentage_width   = 15
    table_width  = metric_width + value_width + percentage_width + 4

    puts "\n#{label} Distribution Stats:"
    puts "-" * table_width
    puts format("%-#{metric_width}s %#{value_width}s %#{percentage_width}s", "Metric", "Value", "Percentage")
    puts "-" * table_width

    puts format("%-#{metric_width}s %#{value_width}d %#{percentage_width}s", "Total records", total, "-")
    puts format(
      "%-#{metric_width}s %#{value_width}d %#{percentage_width}.2f%%",
      "Below threshold (#{threshold})",
      count_low,
      (count_low.to_f / total * 100)
    )
    puts format(
      "%-#{metric_width}s %#{value_width}d %#{percentage_width}.2f%%",
      "Above or equal to threshold",
      count_high,
      (count_high.to_f / total * 100)
    )
    puts format("%-#{metric_width}s %#{value_width}.2f %#{percentage_width}s", "Mean #{label.downcase}", mean, "-")
    puts format("%-#{metric_width}s %#{value_width}.2f %#{percentage_width}s", "Median #{label.downcase}", median, "-")
    puts format("%-#{metric_width}s %#{value_width}.2f %#{percentage_width}s", "Min #{label.downcase}", min_v, "-")
    puts format("%-#{metric_width}s %#{value_width}.2f %#{percentage_width}s", "Max #{label.downcase}", max_v, "-")
    puts "-" * table_width
  end
end

AviatorRoundSeeder.new(record_count: 5000).run
