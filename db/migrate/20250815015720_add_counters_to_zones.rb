class AddCountersToZones < ActiveRecord::Migration[7.0]
  def change
    add_column :zones, :sensors_count, :integer, default: 0
    add_column :zones, :cameras_count, :integer, default: 0
  end
end
