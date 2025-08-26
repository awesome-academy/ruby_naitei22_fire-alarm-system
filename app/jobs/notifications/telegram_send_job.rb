module Notifications
  class TelegramSendJob < ApplicationJob
    queue_as :notifications

    retry_on StandardError, wait: :exponentially_longer, attempts: 5

    rescue_from(StandardError) do |exception|
      log_message = "TelegramSendJob failed permanently: #{exception.message}"
      Rails.logger.error(log_message)
    end

    def perform chat_id:, message:, image_url: nil
      response = if image_url.present?
                   TelegramApiClient.send_photo(
                     chat_id:, photo: image_url, caption: message
                   )
                 else
                   TelegramApiClient.send_message(
                     chat_id:, text: message
                   )
                 end

      handle_response(response, chat_id)
    end

    private

    def handle_response response, chat_id
      return if response.success? && response.parsed_response["ok"]

      parsed_error = response.parsed_response["description"]
      error_msg = parsed_error || "HTTP Status #{response.code}"

      log_message = "Failed to send Telegram notification to " \
                                  "chat_id #{chat_id}: #{error_msg}"
      Rails.logger.fatal(log_message)
    end
  end
end
