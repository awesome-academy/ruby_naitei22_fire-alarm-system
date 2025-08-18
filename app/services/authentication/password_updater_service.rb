# frozen_string_literal: true

module Authentication
  class PasswordUpdaterService
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def initialize token:, password:, password_confirmation:
      @token = token
      @password = password
      @password_confirmation = password_confirmation
    end

    def call
      user = User.find_by(password_reset_token: @token)

      unless user&.password_reset_token_valid?
        return Result.new(success?: false, errors: [t(".invalid_token")])
      end

      update_params = {
        password: @password,
        password_confirmation: @password_confirmation,
        password_reset_token: nil,
        password_reset_sent_at: nil
      }

      if user.update(update_params)
        Result.new(success?: true)
      else
        Result.new(success?: false, errors: user.errors.full_messages)
      end
    end

    private

    def t key
      I18n.t(key, scope: "services.authentication.password_updater")
    end
  end
end
