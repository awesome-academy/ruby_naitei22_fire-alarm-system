module SensorLogs
  class WeatherApiSimulationJob < ApplicationJob
    queue_as :default

    def perform
      SensorLogs::WeatherApiSimulationService.new.run
    end
  end
end
