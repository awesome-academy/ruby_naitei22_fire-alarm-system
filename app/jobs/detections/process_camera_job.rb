module Detections
  class ProcessCameraJob < ApplicationJob
    queue_as :default
    FIRE_LABEL = "FIRE".freeze
    DETECTION_THRESHOLD = ENV.fetch("FIRE_DETECTION_THRESHOLD").to_f

    def perform camera_id:
      @camera = Camera.find_by(id: camera_id)
      return unless @camera

      snapshot_result = capture_snapshot
      unless snapshot_result.success?
        return handle_error("Snapshot failed: #{snapshot_result.error}")
      end

      prediction_service = MlClients::PredictionService.new
      prediction_result = prediction_service.call(
        file_path: snapshot_result.file_path
      )
      unless prediction_result.success?
        return handle_error("Prediction failed: #{prediction_result.error}")
      end

      handle_detection(prediction_result.data, snapshot_result.file_path)
    end

    private

    def capture_snapshot
      live_result = Snapshots::LiveCaptureService.new(camera: @camera).call
      return live_result if live_result.success?

      error_message = <<~MSG.squish
        LiveCaptureService failed for camera ##{@camera.id}:
        #{live_result.error}
      MSG
      Rails.logger.warn(error_message)

      Snapshots::FakeCaptureService.new.call
    end

    def handle_detection prediction, snapshot_path
      return unless fire_detected?(prediction)

      Rails.logger.warn "FIRE DETECTED by AI at Camera: #{@camera.name}"

      result = Alerts::CreationService.new(
        camera: @camera,
        confidence: prediction[:confidence],
        snapshot_path:
      ).call

      unless result.success?
        return handle_error(
          "Failed to create alert: #{result.errors.join(', ')}"
        )
      end

      broadcast_alert(result.alert)
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

    def fire_detected? prediction
      (prediction[:label] == FIRE_LABEL) &&
        (prediction[:confidence] >= DETECTION_THRESHOLD)
    end

    def handle_error message
      Rails.logger.error "ProcessCameraJob (Camera ##{@camera.id}): #{message}"
    end
  end
end
