module Authentication
  class RefreshTokenService
    Result = Struct.new(:success?, :tokens, :error, keyword_init: true)

    def initialize refresh_token:
      @refresh_token = refresh_token
    end

    def call
      token_record = find_token_record
      error = validate_token(token_record)
      return Result.new(success?: false, error:) if error

      new_tokens = TokenGeneratorService.new(token_record.user).call
      Result.new(success?: true, tokens: new_tokens)
    end

    private

    attr_reader :refresh_token

    def find_token_record
      return nil if refresh_token.blank?

      Token.find_by(refresh_token:)
    end

    def validate_token token_record
      unless token_record
        return I18n.t("services.authentication.refresh_token.invalid_token")
      end

      if token_record.expires_at < Time.current
        token_record.destroy
        return I18n.t("services.authentication.refresh_token.token_expired")
      end

      nil
    end
  end
end
