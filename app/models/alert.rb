class Alert < ApplicationRecord
  has_one_attached :snapshot

  enum status: {PENDING: 0, RESOLVED: 1, IGNORED: 2}
  enum origin: {
    SENSOR_THRESHOLD: 0,
    SENSOR_ERROR: 1,
    ML_DETECTION: 2,
    MANUAL_INPUT: 3
  }

  belongs_to :zone, optional: true
  belongs_to :sensor, optional: true
  belongs_to :camera, optional: true
end
