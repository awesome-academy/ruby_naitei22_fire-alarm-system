# frozen_string_literal: true

module Authentication
  class TokenGeneratorService
    ACCESS_TOKEN_LIFESPAN = 15.minutes
    REFRESH_TOKEN_LIFESPAN = 7.days

    def initialize user
      @user = user
    end

    def call
      access_token = generate_access_token
      refresh_token = generate_refresh_token

      ActiveRecord::Base.transaction do
        @user.tokens.destroy_all
        @user.tokens.create!(
          refresh_token:,
          expires_at: REFRESH_TOKEN_LIFESPAN.from_now
        )
      end

      {access_token:, refresh_token:}
    rescue ActiveRecord::RecordInvalid => e
      log_message = "Failed to create token for user #{@user.id}: #{e.message}"
      Rails.logger.error(log_message)
      nil
    end

    private

    attr_reader :user

    def generate_access_token
      Authentication::JsonWebToken.encode({sub: user.id},
                                          ACCESS_TOKEN_LIFESPAN.from_now)
    end

    def generate_refresh_token
      Authentication::JsonWebToken.encode({sub: user.id},
                                          REFRESH_TOKEN_LIFESPAN.from_now)
    end
  end
end
