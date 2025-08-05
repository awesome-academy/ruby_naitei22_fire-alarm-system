class CreateTokens < ActiveRecord::Migration[7.0]
  def change
    create_table :tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :refresh_token, null: false
      t.datetime :expires_at

      t.timestamps
    end

    add_index :tokens, :refresh_token, unique: true
  end
end
