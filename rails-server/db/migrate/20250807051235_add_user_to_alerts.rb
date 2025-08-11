class AddUserToAlerts < ActiveRecord::Migration[7.0]
  def change
    add_reference :alerts, :user, null: true, foreign_key: true
  end
end
