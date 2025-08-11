# frozen_string_literal: true

module Authentication
  class GoogleAuthService < ::BaseService
    def initialize(token:)
      @token = token
    end

    def call
      payload = verify_google_token

      user = User.from_google_payload(payload)
      return failure(user.errors.full_messages) unless user.persisted?

      tokens = Authentication::TokenGeneratorService.new(user: user).call

      Rails.logger.debug "======> Token Result from Service: #{tokens.inspect}"
      return failure("Failed to generate tokens") unless tokens

      success(user:, tokens:)
    rescue Google::Auth::IDTokens::VerificationError => e
      failure(e.message)
    end

    private

    def verify_google_token
      Google::Auth::IDTokens.verify_oidc(
        @token,
        aud: Rails.application.credentials.google[:client_id]
      )
    end
  end
end
