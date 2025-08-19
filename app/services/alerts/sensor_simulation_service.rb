module Alerts
  class SensorSimulationService
    def initialize sensor, simulated_temp, simulated_humidity
      @sensor = sensor
      @simulated_temp = simulated_temp
      @simulated_humidity = simulated_humidity
    end

    def call
      ActiveRecord::Base.transaction do
        log = SensorLog.create!(
          sensor: @sensor,
          temperature: @simulated_temp,
          humidity: @simulated_humidity
        )

        Rails.logger.info(
          I18n.t("weather_api_simulation.log_created",
                 log_id: log.id,
                 sensor_id: @sensor.id)
        )
        broadcast_new_log(log)
        process_alert(log)
      end
    rescue StandardError => e
      Rails.logger.error(
        I18n.t("weather_api_simulation.sensor_log_error",
               sensor_id: @sensor.id,
               error: e.message)
      )
    end

    private

    def broadcast_new_log log
      payload = {
        id: log.id,
        sensor_id: log.sensor_id,
        temperature: log.temperature,
        humidity: log.humidity,
        created_at: log.created_at.iso8601,
        sensor: {
          id: @sensor.id,
          name: @sensor.name,
          status: @sensor.status
        }
      }
      ActionCable.server.broadcast("sensor_logs_channel", payload)
      Rails.logger.info "Broadcasted sensor ##{log.id}"
    end

    def process_alert log
      return unless trigger_condition?(log)

      alert_message = I18n.t(
        "alerts.temperature_exceeded",
        temperature: log.temperature,
        threshold: @sensor.threshold,
        sensor_name: @sensor.name,
        location: @sensor.location
      )

      Rails.logger.warn alert_message

      existing_alert = Alert.find_by(
        owner: @sensor,
        status: :pending,
        origin: :sensor_threshold
      )

      if existing_alert
        existing_alert.update!(message: alert_message)
        broadcast_alert(existing_alert)
      else
        alert = Alert.create!(
          message: alert_message,
          owner: @sensor,
          origin: :sensor_threshold,
          zone_id: @sensor.zone_id,
          via_email: true
        )
        broadcast_alert(alert)
        send_alert_emails(alert)
      end
    end

    def broadcast_alert alert
      payload = {
        id: alert.id,
        message: alert.message,
        origin: alert.origin,
        status: alert.status,
        zone_name: alert.zone.name,
        created_at: alert.created_at.iso8601
      }
      ActionCable.server.broadcast("alerts_channel", payload)
      Rails.logger.info "Broadcasted new alert ##{alert.id} to alerts_channel"
    end

    def trigger_condition? log
      @sensor.threshold &&
        log.temperature &&
        log.temperature >= @sensor.threshold
    end

    def send_alert_emails alert
      recipients = [@sensor&.zone&.user, find_admin]
                   .map{|u| active_user(u)}.compact.uniq

      recipients.each do |user|
        AlertMailer.with(email: user.email,
                         alert:).sensor_threshold_alert.deliver_later
      end
    end

    def find_admin
      supervisor = @sensor&.zone&.user
      User.find_by(id: supervisor&.admin_id, role: :admin) if supervisor
    end

    def active_user user
      return unless user

      return user if user.is_active?

      Rails.logger.warn I18n.t(
        "alerts.email.#{user.role}_inactive",
        name: user.name,
        email: user.email
      )
      nil
    end
  end
end
