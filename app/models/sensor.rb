class Sensor < ApplicationRecord
  enum status: {active: 0, inactive: 1, error: 2}

  belongs_to :zone, counter_cache: true
  has_many :sensor_logs, dependent: :destroy
  has_many :alerts, as: :owner, dependent: :destroy

  # rubocop:disable Rails/HasManyOrHasOneDependent
  has_one :latest_log, ->{newest}, class_name: SensorLog.name
  # rubocop:enable Rails/HasManyOrHasOneDependent
  SENSOR_PERMITTED = %i(name location status zone_id threshold sensitivity
    latitude longitude).freeze

  SENSOR_INDEX_PERMITTED = %i(zone_id status page limit fields).freeze

  PRELOAD = %i(zone latest_log).freeze

  validates :name, presence: true
  validates :location, presence: true
  validates :status, presence: true

  scope :newest, ->{order(created_at: :desc)}
  def self.ransackable_attributes _auth_object = nil
    %w(name location status threshold created_at)
  end

  def self.ransackable_associations _auth_object = nil
    %w(zone)
  end
end
