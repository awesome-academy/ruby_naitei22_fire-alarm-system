module Cloudinary
  class UploadService
    Result = Struct.new(:success?, :url, :public_id, :error,
                        keyword_init: true)
    SNAPSHOT_FOLDER = "fire_alarm/#{Rails.env}/snapshots".freeze

    def call file_path:, public_id: nil
      response = Cloudinary::Uploader.upload(
        file_path,
        public_id:,
          folder: SNAPSHOT_FOLDER,
          resource_type: :image
      )
      Result.new(success?: true, url: response["secure_url"],
                 public_id: response["public_id"])
    rescue Cloudinary::CloudinaryException => e
      Rails.logger.error "Cloudinary Upload Error: #{e.message}"
      Result.new(success?: false,
                 error: I18n.t("services.cloudinary.upload.error",
                               message: e.message))
    end
  end
end
