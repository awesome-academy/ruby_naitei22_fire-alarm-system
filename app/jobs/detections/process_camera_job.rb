module Detections
  class ProcessCameraJob < ApplicationJob
    queue_as :default
    FIRE_LABEL = "FIRE".freeze
    DETECTION_THRESHOLD = ENV.fetch("FIRE_DETECTION_THRESHOLD").to_f

    def perform camera_id:
      @camera = Camera.find_by(id: camera_id)
      return unless @camera

      snapshot_result = Snapshots::FakeCaptureService.new.call
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

    def handle_detection prediction, snapshot_path
      return unless fire_detected?(prediction)

      Rails.logger.warn "FIRE DETECTED by AI at Camera: #{@camera.name}"

      result = Alerts::CreationService.new(
        camera: @camera,
        confidence: prediction[:confidence],
        snapshot_path:
      ).call

      return if result.success?

      handle_error("Failed to create alert: #{result.errors.join(', ')}")
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
