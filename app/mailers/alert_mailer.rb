class AlertMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_SENDER_ADDRESS")

  def new_alert_notification alert
    @alert = alert
    recipient = @alert.notification_recipient
    return unless recipient&.email

    attach_snapshot_if_present
    mail(to: recipient.email, subject: t(".subject"))
  end

  private

  def attach_snapshot_if_present
    return unless @alert.snapshot.attached?

    attachments.inline[@alert.snapshot.filename.to_s] =
      @alert.snapshot.download
  end
end
