class AddForeignKeyToSensorLogs < ActiveRecord::Migration[7.0]
  def change
    if foreign_key_exists?(:sensor_logs, :sensors)
      remove_foreign_key :sensor_logs, :sensors
    end

    add_foreign_key :sensor_logs, :sensors, on_delete: :cascade
  end
end
