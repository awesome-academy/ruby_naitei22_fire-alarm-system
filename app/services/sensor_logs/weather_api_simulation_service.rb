require "net/http"
require "json"

module SensorLogs
  class WeatherApiSimulationService
    def initialize
      @api_key  = ENV["WEATHERAPI_API_KEY"]
      @base_url = Settings.weatherapi_url
    end

    def run
      if @api_key.blank?
        Rails.logger.warn(
          I18n.t("weather_api_simulation.missing_api_key")
        )
        return
      end

      zones = load_target_zones
      if zones.empty?
        Rails.logger.info(
          I18n.t("weather_api_simulation.no_zones_found")
        )
        return
      end

      zones.each{|zone| process_zone(zone)}
    rescue StandardError => e
      Rails.logger.error(
        I18n.t("weather_api_simulation.unexpected_error", error: e.message)
      )
    end

    private

    def load_target_zones
      Zone.includes(:sensors).with_location.with_active_sensors
    end

    def process_zone zone
      location_query, location_label = build_location(zone)
      Rails.logger.info(
        I18n.t("weather_api_simulation.processing_zone",
               zone_id: zone.id,
               location: location_label)
      )

      weather = fetch_weather(location_query)
      return unless weather

      outdoor_temp     = weather.dig("current", "temp_c")
      outdoor_humidity = weather.dig("current", "humidity")

      unless outdoor_temp && outdoor_humidity
        Rails.logger.warn(
          I18n.t("weather_api_simulation.missing_weather_data",
                 zone_id: zone.id)
        )
        return
      end

      zone.sensors.each do |sensor|
        simulate_and_log(sensor, outdoor_temp, outdoor_humidity)
      end
    end

    def build_location zone
      if zone.latitude && zone.longitude
        [
          "#{zone.latitude},#{zone.longitude}",
          "Lat/Lon (#{zone.latitude},#{zone.longitude})"
        ]
      else
        [zone.city, "City (#{zone.city})"]
      end
    end

    def fetch_weather query
      uri = URI("#{@base_url}?key=#{@api_key}&q=#{query}&aqi=no")
      response = Net::HTTP.get(uri)
      JSON.parse(response)
    rescue JSON::ParserError => e
      Rails.logger.error(
        I18n.t("weather_api_simulation.json_parse_error", error: e.message)
      )
      nil
    rescue SocketError, Errno::ECONNREFUSED, Timeout::Error => e
      Rails.logger.error(
        I18n.t("weather_api_simulation.network_error", error: e.message)
      )
      nil
    rescue StandardError => e
      Rails.logger.error(
        I18n.t("weather_api_simulation.api_error", error: e.message)
      )
      nil
    end

    def simulate_and_log sensor, outdoor_temp, outdoor_humidity
      simulated_temp, simulated_humidity =
        simulate_sensor(sensor, outdoor_temp, outdoor_humidity)

      return unless simulated_temp || simulated_humidity

      Alerts::SensorSimulationService.new(sensor, simulated_temp,
                                          simulated_humidity).call
    end

    def simulate_sensor sensor, outdoor_temp, outdoor_humidity
      simulated_temp     = simulate_temperature(sensor, outdoor_temp)
      simulated_humidity = simulate_humidity(outdoor_humidity)

      [simulated_temp, simulated_humidity]
    end

    def simulate_temperature sensor, outdoor_temp
      base_temp      = 22
      temp_influence = (outdoor_temp - 15) * 0.1
      temp_noise     = (rand - 0.5)
      simulated_temp = (base_temp + temp_influence + temp_noise).round(2)

      return simulated_temp unless sensor.threshold

      adjust_for_threshold(sensor, simulated_temp)
    end

    def adjust_for_threshold sensor, simulated_temp
      if rand < 0.05
        sensor.threshold + rand * 2
      elsif simulated_temp >= sensor.threshold
        Rails.logger.warn(
          I18n.t("weather_api_simulation.temp_exceeds",
                 temp: simulated_temp,
                 threshold: sensor.threshold)
        )
        simulated_temp
      else
        [simulated_temp, sensor.threshold - 0.5].min
      end
    end

    def simulate_humidity outdoor_humidity
      base_humidity      = 45
      humidity_influence = (outdoor_humidity - 50) * 0.05
      humidity_noise     = (rand - 0.5) * 2
      simulated_humidity = base_humidity + humidity_influence + humidity_noise

      [[simulated_humidity.round(2), 0].max, 100].min
    end
  end
end
