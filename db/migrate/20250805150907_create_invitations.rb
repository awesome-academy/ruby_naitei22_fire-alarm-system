class CreateInvitations < ActiveRecord::Migration[7.0]
  def change
    create_table :invitations do |t|
      t.string :code, null: false
      t.string :purpose, null: false
      t.boolean :used, default: false, null: false
      t.datetime :expires_at
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :invitations, :code, unique: true
  end
end
