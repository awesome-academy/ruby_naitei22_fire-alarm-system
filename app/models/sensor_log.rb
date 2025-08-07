class SensorLog < ApplicationRecord
  acts_as_paranoid

  belongs_to :sensor

  validates :sensor_id, presence: true
  validates :temperature, numericality: true, allow_nil: true
  validates :humidity, numericality: true, allow_nil: true

  scope :recent_hours, ->(hours){where("created_at >= ?", hours.hours.ago)}
  scope :with_temperature, ->{where.not(temperature: nil)}
  scope :by_sensor_ids, ->(sensor_ids){where(sensor_id: sensor_ids)}
  scope :created_after, ->(time){where("created_at >= ?", time)}
  scope :in_time_range, (lambda do |start_time, end_time|
    where(created_at: start_time..end_time)
  end)

  CHART_DATA_COLUMNS = %w(sensor_id created_at temperature humidity).freeze
end
