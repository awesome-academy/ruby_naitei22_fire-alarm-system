module Sensors
  class SensorService
    def initialize; end

    def get_stats
      {
        active: Sensor.active.count,
        inactive: Sensor.inactive.count,
        faulty: Sensor.error.count
      }
    end

    def bulk sensor_list
      zone_ids = sensor_list.map{|s| s[:zone_id]}.uniq.compact
      existing_ids = Zone.where(id: zone_ids).pluck(:id)
      missing_ids = zone_ids - existing_ids

      if missing_ids.any?
        sensor = Sensor.new
        sensor.errors.add(:base,
                          I18n.t("api.v1.sensors.bulk.missing_zone",
                                 ids: missing_ids.join(", ")))
        raise ActiveRecord::RecordInvalid, sensor
      end

      sensors = sensor_list.map{|sensor_params| Sensor.new(sensor_params)}

      Sensor.import sensors, validate: true
      {inserted: sensors.size}
    end

    def find_all filters
      Sensor.includes(Sensor::PRELOAD)
            .by_zone(filters[:zone_id])
            .by_status(filters[:status])
            .newest
    end

    def find_one id
      Sensor.includes(Sensor::PRELOAD).find_by(id:)
    end
  end
end
