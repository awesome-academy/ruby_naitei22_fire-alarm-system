class AlertMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_SENDER_ADDRESS")

  def new_alert_notification alert
    @alert = alert
    recipient = @alert.notification_recipient
    return unless recipient&.email && @alert.via_email?

    mail(to: recipient.email, subject: t(".subject"))
  end
end
