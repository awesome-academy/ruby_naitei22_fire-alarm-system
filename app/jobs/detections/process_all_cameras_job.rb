module Detections
  class ProcessAllCamerasJob < ApplicationJob
    queue_as :default

    def perform
      camera_ids = Camera.online_and_detecting.pluck(:id)

      if camera_ids.empty?
        Rails.logger.info "No cameras to scan."
        return
      end

      Rails.logger.info "Queuing scan jobs for #{camera_ids.count} cameras..."
      camera_ids.each do |camera_id|
        ProcessCameraJob.perform_later(camera_id:)
      end
    end
  end
end
