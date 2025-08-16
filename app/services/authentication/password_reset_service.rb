module Authentication
  class PasswordResetService
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def initialize email:
      @email = email
    end

    def call
      user = User.find_by(email: @email)

      if user
        user.generate_password_reset_token!
        user.send_password_reset_email!
      end

      Result.new(success?: true)
    end
  end
end
