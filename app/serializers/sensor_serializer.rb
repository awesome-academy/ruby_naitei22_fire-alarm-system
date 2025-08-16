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

  def latest_log
    log = object.latest_log
    return unless log

    {
      temperature: log.temperature,
      humidity: log.humidity,
      created_at: log.created_at
    }
  end
end
