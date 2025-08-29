class RemoveSensorIdFromAlerts < ActiveRecord::Migration[7.0]
  def change
    remove_column :alerts, :sensor_id, :bigint
  end
end
