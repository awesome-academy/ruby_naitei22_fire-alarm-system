class AddUniqueIndexToZonesNameAndUserId < ActiveRecord::Migration[7.0]
  def change
    add_index :zones, [:name, :user_id], unique: true
  end
end
