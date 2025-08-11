module Cameras
  class SnapshotService
    Result = Struct.new(:success?, :camera, :error, keyword_init: true)

    def initialize camera:
      @camera = camera
    end

    def call
      capture_result = Snapshots::FakeCaptureService.new.call
      unless capture_result.success?
        return Result.new(success?: false,
                          error: capture_result.error)
      end

      upload_result = upload_to_cloudinary(capture_result.file_path)
      unless upload_result.success?
        return Result.new(success?: false,
                          error: upload_result.error)
      end

      if @camera.update(last_snapshot_url: upload_result.url)
        Result.new(success?: true, camera: @camera)
      else
        Result.new(
          success?: false,
          error: @camera.errors.full_messages.join(", "),
          status_code: :unprocessable_entity
        )
      end
    end

    private

    def upload_to_cloudinary file_path
      Cloudinary::UploadService.new.call(
        file_path:,
        public_id: generate_public_id
      )
    end

    def generate_public_id
      "camera_#{@camera.id}_#{@camera.name.parameterize}_#{Time.current.to_i}"
    end
  end
end
