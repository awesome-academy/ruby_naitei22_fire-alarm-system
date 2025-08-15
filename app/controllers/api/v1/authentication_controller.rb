# frozen_string_literal: true

class Api::V1::AuthenticationController < Api::V1::BaseController
  ACCESS_TOKEN_EXPIRES_IN = 15.minutes
  REFRESH_TOKEN_EXPIRES_IN = 7.days
  SIGNUP_PARAMS_PERMIT = %i(name email password phone invitation_code).freeze

  before_action :authenticate_request!, only: %i(profile update_role)
  before_action :authorize_admin!, only: %i(update_role)
  before_action :set_user_to_update, only: %i(update_role)
  skip_before_action :authenticate_request!,
                     only: %i(forgot_password reset_password), raise: false

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
    result = Authentication::RoleUpdaterService.new(
      user_to_update: @user_to_update,
      current_user: @current_user,
      new_role: params[:role]
    ).call

    if result.success?
      render_success(
        {
          message: t(".success"),
          user: UserSerializer.new(result.user)
        },
        result.status
      )
    else
      render_error(result.errors, result.status)
    end
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

  # POST /api/v1/auth/forgot_password
  def forgot_password
    service = Authentication::PasswordResetService.new(email: params[:email])
    service.call
    render_success({message: t(".forgot_password.success")}, :ok)
  end

  # POST /api/v1/auth/reset_password
  def reset_password
    service = Authentication::PasswordUpdaterService.new(
      token: params[:token],
      password: params[:password],
      password_confirmation: params[:password_confirmation]
    )
    result = service.call

    if result.success?
      render_success({message: t(".reset_password.success")}, :ok)
    else
      render_error(result.errors, :unprocessable_entity)
    end
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

  def set_user_to_update
    @user_to_update = User.find_by(id: params[:user_id])
    return if @user_to_update

    render_error(t(".user_not_found"), :not_found)
  end
end
