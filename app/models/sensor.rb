class Sensor < ApplicationRecord
  enum status: {ACTIVE: 0, INACTIVE: 1, ERROR: 2}

  belongs_to :zone
  has_many :sensor_logs, dependent: :destroy
  has_many :alerts, dependent: :nullify
end
