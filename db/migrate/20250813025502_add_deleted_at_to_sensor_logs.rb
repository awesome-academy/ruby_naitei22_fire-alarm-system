class AddDeletedAtToSensorLogs < ActiveRecord::Migration[7.0]
  def change
    add_column :sensor_logs, :deleted_at, :datetime
    add_index :sensor_logs, :deleted_at
  end
end
