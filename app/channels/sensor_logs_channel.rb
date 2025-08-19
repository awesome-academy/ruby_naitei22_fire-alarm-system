# frozen_string_literal: true

class SensorLogsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "sensor_logs_channel"
    Rails.logger.debug "Client subscribed to sensor_logs_channel"
  end

  def unsubscribed; end
end
