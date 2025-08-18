module Authentication
  class PasswordResetService
    Result = Struct.new(:success?, :errors, keyword_init: true)

    def initialize email:
      @email = email
    end

    def call
      user = User.find_by(email: @email)
      if user
        begin
          ActiveRecord::Base.transaction do
            user.generate_password_reset_token!
            user.send_password_reset_email!
          end
        rescue StandardError => e
          log_message = <<~LOG.squish
            PasswordResetService failed for user #{user.id}:
            #{e.class} - #{e.message}
          LOG
          Rails.logger.error(log_message)
          return Result.new(success?: false, errors: [t(".generic_error")])
        end
      end
      Result.new(success?: true)
    end

    private

    def t key
      I18n.t(key, scope: "services.authentication.password_reset")
    end
  end
end
