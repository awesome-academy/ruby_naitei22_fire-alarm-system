class CreateCameras < ActiveRecord::Migration[7.0]
  def change
    create_table :cameras do |t|
      t.string :name
      t.string :url
      t.references :zone, null: false, foreign_key: true
      t.float :latitude
      t.float :longitude
      t.integer :status, default: 0
      t.boolean :is_detecting, default: false
      t.string :last_snapshot_url

      t.timestamps
    end
  end
end
