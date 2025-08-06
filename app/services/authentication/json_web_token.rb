module Authentication
  class JsonWebToken
    SECRET_KEY = Rails.application.credentials.jwt_secret_key!
    ALGORITHM_TYPE = "HS256".freeze

    def self.encode payload, exp = default_expiration
      payload[:exp] = exp.to_i
      JWT.encode(payload, SECRET_KEY, ALGORITHM_TYPE)
    end

    def self.decode token
      decoded = JWT.decode(token, SECRET_KEY, true,
                           {algorithm: ALGORITHM_TYPE}).first
      HashWithIndifferentAccess.new(decoded)
    end

    def self.default_expiration
      24.hours.from_now
    end
  end
end
