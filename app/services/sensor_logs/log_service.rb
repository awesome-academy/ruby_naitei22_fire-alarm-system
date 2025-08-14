module SensorLogs
  class LogService
    DEFAULT_RANGE_HOURS = 24

    def get_stats range_hours = DEFAULT_RANGE_HOURS
      start_time = range_hours.hours.ago

      logs = SensorLog
             .created_after(start_time)
             .with_temperature

      {
        average_temperature: logs.average(:temperature),
        average_humidity: logs.average(:humidity),
        message: I18n.t(
          "api.v1.sensor_logs.stats.success",
          hours: range_hours
        )
      }
    end

    def get_chart_data sensor_ids, start_time = nil, end_time = nil
      start_time ||= DEFAULT_RANGE_HOURS.hours.ago
      end_time   ||= Time.current

      logs = fetch_logs(sensor_ids, start_time, end_time)
      build_chart_data(logs)
    end

    private

    def fetch_logs sensor_ids, start_time, end_time
      SensorLog
        .by_sensor_ids(sensor_ids)
        .in_time_range(start_time, end_time)
        .order(:created_at)
        .pluck(*SensorLog::CHART_DATA_COLUMNS)
    end

    def build_chart_data logs
      logs.each_with_object({}) do |values, chart_data|
        sensor_id, timestamp, temperature, humidity = values

        chart_data[sensor_id] ||= []
        chart_data[sensor_id] << {
          timestamp:,
          temperature:,
          humidity:
        }
      end
    end
  end
end
