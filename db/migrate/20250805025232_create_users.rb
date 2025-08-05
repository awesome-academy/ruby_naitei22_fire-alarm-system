class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :name
      t.string :password_digest
      t.string :email, null: false
      t.string :phone
      t.string :address
      t.integer :role, default: 0
      t.references :admin, null: true, foreign_key: { to_table: :users }
      t.boolean :is_active, default: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :phone, unique: true
  end
end
