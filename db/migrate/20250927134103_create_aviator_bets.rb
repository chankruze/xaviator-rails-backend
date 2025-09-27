class CreateAviatorBets < ActiveRecord::Migration[8.0]
  def change
    create_table :aviator_bets do |t|
      t.references :user, null: false, foreign_key: true
      t.references :aviator_round, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :aviator_bets, [ :user_id, :aviator_round_id ], unique: true
  end
end
