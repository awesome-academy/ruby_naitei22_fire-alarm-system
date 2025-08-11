# frozen_string_literal: true

module Authentication
  class RegistrationService
    Result = Struct.new(:success?, :user, :tokens, :errors, keyword_init: true)

    def initialize params:
      @params = params
    end

    def call
      signup_result = SignupService.new(@params).call
      unless signup_result.success?
        return Result.new(success?: false,
                          errors: signup_result.errors)
      end

      user = signup_result.user
      tokens = TokenGeneratorService.new(user).call
      Result.new(success?: true, user:, tokens:)
    end
  end
end
