# frozen_string_literal: true

class Api::V1::AuthenticationController < Api::V1::BaseController
  ACCESS_TOKEN_EXPIRES_IN = 15.minutes
  REFRESH_TOKEN_EXPIRES_IN = 7.days
  SIGNUP_PARAMS_PERMIT = %i(name email password phone invitation_code).freeze

  before_action :authenticate_request!, only: %i(profile update_role)
  before_action :authorize_admin!, only: %i(update_role)

  # POST /api/v1/auth/signup
  def signup
    result = Authentication::RegistrationService.new(params: signup_params).call

    unless result.success?
      return render_error(result.errors, :unprocessable_entity)
    end

    set_auth_cookies(result.tokens)
    render_success(
      {
        message: t("api.v1.authentication.signup.success"),
        user: UserSerializer.new(result.user)
      },
      :created
    )
  end

  # POST /api/v1/auth/login
  def login
    result = Authentication::LoginService.new(
      email: params[:email],
      password: params[:password]
    ).call

    return render_error(result.error, :unauthorized) unless result.success?

    set_auth_cookies(result.tokens)
    render_success({message: t("api.v1.authentication.login.success")}, :ok)
  end

  # POST /api/v1/auth/logout
  def logout
    Token.find_by(refresh_token: cookies[:refreshToken])&.destroy
    clear_auth_cookies
    render_success({message: t("api.v1.authentication.logout.success")}, :ok)
  end

  # GET /api/v1/auth/profile
  def profile
    render json: @current_user, serializer: UserSerializer, status: :ok
  end

  # PATCH /api/v1/auth/role
  def update_role
    render json: {message: t("api.v1.authentication.implemented")},
           status: :not_implemented
  end

  # POST /api/v1/auth/refresh
  def refresh
    result = Authentication::RefreshTokenService.new(
      refresh_token: cookies[:refreshToken]
    ).call

    return render_error(result.error, :unauthorized) unless result.success?

    set_auth_cookies(result.tokens)
    render_success({message: t(".success")}, :ok)
  end

  private

  def signup_params
    params.require(:auth)
  end

  def set_auth_cookies tokens
    set_cookie(:accessToken, tokens[:access_token], ACCESS_TOKEN_EXPIRES_IN)
    set_cookie(:refreshToken, tokens[:refresh_token], REFRESH_TOKEN_EXPIRES_IN)
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

  def render_success data, status
    render json: data, status:
  end

  def render_error errors, status
    render json: {errors:}, status:
  end
end
