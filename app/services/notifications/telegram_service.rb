# frozen_string_literal: true

module Notifications
  class TelegramService
    TIMEZONE = "Asia/Ho_Chi_Minh"
    TIMESTAMP_FORMAT = "%H:%M:%S %d/%m/%Y"

    def initialize alert:
      @alert = alert
      @chat_id = ENV.fetch("TELEGRAM_CHAT_ID", nil)
    end

    def call
      return unless bot_configured?

      Notifications::TelegramSendJob.perform_later(
        chat_id: @chat_id,
        message: build_message,
        image_url: @alert.image_url
      )
    end

    private

    attr_reader :alert

    def bot_configured?
      if ENV["TELEGRAM_BOT_TOKEN"].blank? || @chat_id.blank?
        Rails.logger.warn "Telegram Bot not configured. Skipping notification."
        return false
      end
      true
    end

    def build_message
      I18n.t("services.notifications.telegram.message_html", i18n_params)
    end

    def i18n_params
      {
        zone_name: alert.zone.name,
        owner_name: alert.owner.name,
        owner_type: alert.owner_type,
        timestamp: formatted_timestamp,
        message: alert.message
      }
    end

    def formatted_timestamp
      alert.created_at.in_time_zone(TIMEZONE).strftime(TIMESTAMP_FORMAT)
    end
  end
end
