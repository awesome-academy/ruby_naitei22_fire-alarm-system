class CreateOauthAccounts < ActiveRecord::Migration[7.0]
  def change
    create_table :oauth_accounts do |t|
      t.string :provider
      t.string :uid
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
