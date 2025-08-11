class CreateSensorLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :sensor_logs do |t|
      t.references :sensor, null: false, foreign_key: true
      t.float :temperature
      t.float :humidity

      t.datetime :detected_at
      t.datetime :created_at, null: true, default: nil
      t.datetime :updated_at, null: true, default: nil
    end
  end
end
