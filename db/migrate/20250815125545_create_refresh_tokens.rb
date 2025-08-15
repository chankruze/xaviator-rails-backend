class CreateRefreshTokens < ActiveRecord::Migration[8.0]
  def change
    create_table :refresh_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :jti, null: false              # server-generated ID for rotation tracking
      t.string  :token_digest, null: false     # store a hash of the token, not the raw token
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.string :user_agent
      t.string :ip

      t.timestamps
    end

    add_index :refresh_tokens, :jti, unique: true
    add_index :refresh_tokens, :token_digest, unique: true
    add_index :refresh_tokens, [ :user_id, :expires_at ]
  end
end
