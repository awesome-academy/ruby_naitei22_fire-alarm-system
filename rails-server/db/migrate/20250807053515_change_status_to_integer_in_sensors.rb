class ChangeStatusToIntegerInSensors < ActiveRecord::Migration[7.0]
  def up
    Sensor.reset_column_information
    Sensor.find_each do |sensor|
      new_status = case sensor.status&.downcase
                   when "active" then 0
                   when "inactive" then 1
                   when "error" then 2
                   else 0 # default fallback
                   end
      sensor.update_column(:status, new_status)
    end

    change_column :sensors, :status, :integer, default: 0, null: false
  end

  def down
    change_column :sensors, :status, :string, default: "active"
  end
end
