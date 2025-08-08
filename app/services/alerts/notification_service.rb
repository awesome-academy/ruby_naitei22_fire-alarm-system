module Alerts
  class NotificationService
    def initialize alert:
      @alert = alert
    end

    def call
      send_email_notification
    end

    private

    def send_email_notification
      return unless @alert.via_email?

      AlertMailer.new_alert_notification(@alert).deliver_later
      Rails.logger.info "Queued email notification for Alert ##{@alert.id}"
    end
  end
end
