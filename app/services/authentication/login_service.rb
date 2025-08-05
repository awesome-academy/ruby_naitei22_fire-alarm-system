# frozen_string_literal: true

module Authentication
  class LoginService
    Result = Struct.new(:success?, :user, :tokens, :error, keyword_init: true)

    def initialize email:, password:
      @email = email
      @password = password
    end

    def call
      user = find_user
      error = validate_user(user)
      return Result.new(success?: false, error:) if error

      tokens = TokenGeneratorService.new(user).call
      Result.new(success?: true, user:, tokens:)
    end

    private

    attr_reader :email, :password

    def find_user
      User.find_by(email:)
    end

    def validate_user user
      unless user&.authenticate(password)
        return I18n.t("services.authentication.login.invalid_credentials")
      end
      unless user.is_active?
        return I18n.t("services.authentication.login.not_active")
      end

      nil
    end
  end
end
