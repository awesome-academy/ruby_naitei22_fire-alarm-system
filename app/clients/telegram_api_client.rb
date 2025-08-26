# frozen_string_literal: true

class TelegramApiClient
  include HTTParty

  BASE_URI = "https://api.telegram.org/bot#{ENV.fetch('TELEGRAM_BOT_TOKEN',
                                                      nil)}".freeze
  SEND_PHOTO_PATH = "/sendPhoto"
  SEND_MESSAGE_PATH = "/sendMessage"
  DEFAULT_PARSE_MODE = "Markdown"

  base_uri BASE_URI

  def self.send_message chat_id:, text:
    post(SEND_MESSAGE_PATH,
         body: {chat_id:, text:, parse_mode: DEFAULT_PARSE_MODE})
  end

  def self.send_photo chat_id:, photo:, caption:
    post(SEND_PHOTO_PATH,
         body: {chat_id:, photo:, caption:, parse_mode: DEFAULT_PARSE_MODE})
  end
end
