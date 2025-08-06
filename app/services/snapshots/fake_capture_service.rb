module Snapshots
  class FakeCaptureService
    Result = Struct.new(:success?, :file_path, :error, keyword_init: true)
    # rubocop:disable Rails/FilePath
    SAMPLE_DIR = Rails.root.join("public", "sample_snapshots")
    # rubocop:enable Rails/FilePath

    def call
      image_files = Dir.glob("#{SAMPLE_DIR}/*.{jpg,jpeg,png}")
      if image_files.empty?
        error_key = "services.snapshots.fake_capture.no_samples_found"
        error_message = I18n.t(error_key, dir: SAMPLE_DIR)
        return Result.new(success?: false, error: error_message)
      end

      random_image_path = image_files.sample
      Result.new(success?: true, file_path: random_image_path)
    end
  end
end
