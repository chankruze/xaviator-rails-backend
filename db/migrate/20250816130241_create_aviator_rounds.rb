class CreateAviatorRounds < ActiveRecord::Migration[8.0]
  def change
    create_table :aviator_rounds do |t|
      t.integer :status
      t.float   :crash_point
      t.integer :betting_duration
      t.float   :house_edge
      t.float   :max_multiplier
      t.datetime :betting_started_at
      t.datetime :betting_ends_at
      t.datetime :crashed_at

      t.timestamps
    end
  end
end
