class SensorSerializer < ActiveModel::Serializer
  attributes :id,
             :name,
             :location,
             :status,
             :threshold,
             :sensitivity,
             :zone_id,
             :latitude,
             :longitude,
             :created_at,
             :updated_at,
             :latest_log

  belongs_to :zone
  has_many :sensor_logs

  def latest_log
    latest = object.sensor_logs.order(created_at: :desc).first
    return unless latest

    {
      temperature: latest.temperature,
      humidity: latest.humidity,
      created_at: latest.created_at
    }
  end
end
