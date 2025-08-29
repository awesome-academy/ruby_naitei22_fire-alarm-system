module Authentication
  module CookieHelpers
    ACCESS_TOKEN_EXPIRES_IN = 15.minutes
    REFRESH_TOKEN_EXPIRES_IN = 7.days
    def set_auth_cookies tokens
      set_cookie(:accessToken, tokens[:access_token], ACCESS_TOKEN_EXPIRES_IN)
      set_cookie(:refreshToken, tokens[:refresh_token],
                 REFRESH_TOKEN_EXPIRES_IN)
    end

    def clear_auth_cookies
      cookies.delete(:accessToken)
      cookies.delete(:refreshToken)
    end

    def set_cookie key, value, expires_in
      cookies[key] = {
        value:,
        expires: expires_in.from_now,
        httponly: true,
        secure: Rails.env.production?,
        same_site: :lax,
        path: "/"
      }
    end
  end
end
