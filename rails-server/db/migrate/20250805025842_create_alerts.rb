class CreateAlerts < ActiveRecord::Migration[7.0]
  def change
    create_table :alerts do |t|
      t.text :message
      t.integer :origin, default: 0
      t.references :owner, polymorphic: true, null: false, index: true
      t.references :zone, null: false, foreign_key: true
      t.string :image_url
      t.integer :status, default: 0
      t.boolean :via_email, default: true
      t.timestamps null: false
    end
  end
end
