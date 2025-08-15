module Alerts
  class CreationService
    Result = Struct.new(:success?, :alert, :errors, keyword_init: true)

    def initialize camera:, confidence:, snapshot_path:
      @camera = camera
      @confidence = confidence
      @snapshot_path = snapshot_path
    end

    def call
      upload_result = upload_to_cloudinary(@snapshot_path)
      unless upload_result.success?
        return Result.new(
          success?: false,
          errors: [upload_result.error]
        )
      end

      alert = @camera.alerts.build(
        message: generate_message,
        origin: :ml_detection,
        image_url: upload_result.url,
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

    def upload_to_cloudinary file_path
      Cloudinary::UploadService.new.call(file_path:)
    end

    def generate_message
      <<~MESSAGE.squish
        FIRE DETECTED by AI at camera '#{@camera.name}'.
        Confidence: #{@confidence.round(2)}
      MESSAGE
    end
  end
end
