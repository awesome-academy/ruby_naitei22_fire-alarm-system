class AddSensorRefToAlerts < ActiveRecord::Migration[7.0]
  def change
    add_reference :alerts, :sensor, null: false, foreign_key: true
  end
end
