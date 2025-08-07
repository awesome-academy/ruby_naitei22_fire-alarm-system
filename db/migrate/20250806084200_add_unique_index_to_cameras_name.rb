class AddUniqueIndexToCamerasName < ActiveRecord::Migration[7.0]
  def change
    add_index :cameras, [:zone_id, :name], unique: true
  end
end
