class CreateZones < ActiveRecord::Migration[7.0]
  def change
    create_table :zones do |t|
      t.string     :name
      t.references :user, null: false, foreign_key: true
      t.text       :description
      t.string     :city
      t.float      :latitude
      t.float      :longitude

      t.timestamps
    end
  end
end
