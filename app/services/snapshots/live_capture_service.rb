# frozen_string_literal: true

require "open3"

module Snapshots
  class LiveCaptureService
    Result = Struct.new(:success?, :file_path, :error, keyword_init: true)
    SNAPSHOT_DIR = Rails.root.join("tmp/snapshots")
    CAPTURE_TIMEOUT = 10

    def initialize camera:
      @camera = camera
      @rtsp_url = camera.url
      FileUtils.mkdir_p(SNAPSHOT_DIR) unless Dir.exist?(SNAPSHOT_DIR)
    end

    def call
      output_path = generate_output_path
      command = build_ffmpeg_command(output_path)

      log_command(command)
      execute_command(command, output_path)
    rescue StandardError => e
      handle_exception(e)
    end

    private

    def generate_output_path
      SNAPSHOT_DIR.join("camera_#{@camera.id}_#{Time.now.to_i}.jpg")
    end

    def build_ffmpeg_command output_path
      [
        "ffmpeg",
          "-hide_banner", "-loglevel", "error",
          "-rtsp_transport", "tcp",
          "-i", @rtsp_url,
          "-ss", "1",
          "-vframes", "1",
          "-y",
          "-f", "image2",
          output_path.to_s
      ]
    end

    def log_command command
      log_message = "Executing FFMPEG for camera ##{@camera.id}: " \
                    "#{command.join(' ')}"
      Rails.logger.info log_message
    end

    def execute_command command, output_path
      _stdout, stderr, status = Open3.capture3(*command)

      if status.success? &&
         File.exist?(output_path) &&
         File.size(output_path).positive?
        handle_success(output_path)
      else
        handle_failure(stderr)
      end
    end

    def handle_success output_path
      Result.new(success?: true, file_path: output_path.to_s)
    end

    def handle_failure stderr
      error_message = <<~MSG.squish
        FFMPEG command failed for camera ##{@camera.id}.
        Stderr: #{stderr.strip}
      MSG
      Rails.logger.error error_message
      Result.new(success?: false, error: error_message)
    end

    def handle_exception exception
      error_message = <<~MSG.squish
        FFMPEG direct execution failed for camera ##{@camera.id}:
        #{exception.message}
      MSG
      Rails.logger.error error_message
      Result.new(success?: false, error: error_message)
    end
  end
end
