class Sensor < ApplicationRecord
  enum status: {active: 0, inactive: 1, error: 2}

  belongs_to :zone
  has_many :sensor_logs, dependent: :destroy
  has_many :alerts, dependent: :nullify

  SENSOR_PERMITTED = %i(name location status zone_id threshold sensitivity
    latitude longitude).freeze

  SENSOR_INDEX_PERMITTED = %i(zone_id status page limit).freeze

  PRELOAD = %i(zone sensor_logs).freeze

  validates :name, presence: true
  validates :location, presence: true
  validates :status, presence: true

  scope :newest, ->{order(created_at: :desc)}
  scope :by_zone, ->(zone_id){where(zone_id:) if zone_id.present?}
  scope :by_status, ->(status){where(status:) if status.present?}
end
