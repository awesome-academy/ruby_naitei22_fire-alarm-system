class AlertsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "alerts_channel"
    Rails.logger.debug "Client subscribed to alerts_channel"
  end

  def unsubscribed
    Rails.logger.debug "Client unsubscribed from alerts_channel"
  end
end
