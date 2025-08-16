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
        key = "services.authentication.password_updater.invalid_token"
        error_message = I18n.t(key)
        return Result.new(success?: false, errors: [error_message])
      end

      if user.update(password: @password,
                     password_confirmation: @password_confirmation)
        user.clear_password_reset_token!
        Result.new(success?: true)
      else
        Result.new(success?: false, errors: user.errors.full_messages)
      end
    end
  end
end
