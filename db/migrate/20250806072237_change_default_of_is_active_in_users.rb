class ChangeDefaultOfIsActiveInUsers < ActiveRecord::Migration[7.0]
  def change
    change_column_default :users, :is_active, from: false, to: true
  end
end
