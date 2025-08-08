module Alerts
  class CreationService
    Result = Struct.new(:success?, :alert, :errors, keyword_init: true)

    def initialize camera:, confidence:, snapshot_path:
      @camera = camera
      @confidence = confidence
      @snapshot_path = snapshot_path
    end

    def call
      image_url = upload_snapshot

      alert = @camera.alerts.build(
        message: generate_message,
        origin: :ml_detection,
        image_url:,
        zone: @camera.zone
      )

      if alert.save
        NotificationService.new(alert:).call
        Result.new(success?: true, alert:)
      else
        Result.new(success?: false, errors: alert.errors.full_messages)
      end
    end

    private

    def upload_snapshot
      upload_service = Cloudinary::UploadService.new
      upload_result = upload_service.call(file_path: @snapshot_path)
      upload_result.success? ? upload_result.url : nil
    end

    def generate_message
      "FIRE DETECTED by AI at camera '#{@camera.name}'. " \
      "Confidence: #{@confidence.round(2)}"
    end
  end
end
