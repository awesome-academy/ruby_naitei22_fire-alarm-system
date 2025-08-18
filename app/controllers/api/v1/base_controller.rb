# frozen_string_literal: true

class Api::V1::BaseController < ApplicationController
  skip_forgery_protection
  include ActionController::Cookies

  class NotAuthenticatedError < StandardError; end

  class NotAuthorizedError < StandardError; end

  rescue_from NotAuthenticatedError, with: :handle_authentication_error
  rescue_from NotAuthorizedError, with: :handle_authorization_error
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  before_action :set_locale

  private

  attr_reader :current_user

  def authenticate_request!
    token = decoded_token
    @current_user = User.find_by(id: token["sub"]) if token
    return if @current_user

    raise NotAuthenticatedError,
          t("api.v1.base_controller.errors.auth_failed")
  end

  def decoded_token
    token = cookies[:accessToken]
    unless token
      raise NotAuthenticatedError,
            t("api.v1.base_controller.errors.missing_token")
    end

    Authentication::JsonWebToken.decode(token)
  rescue JWT::ExpiredSignature
    raise NotAuthenticatedError,
          t("api.v1.base_controller.errors.token_expired")
  rescue JWT::DecodeError => e
    raise NotAuthenticatedError,
          t("api.v1.base_controller.errors.invalid_token", error: e.message)
  end

  def authorize_admin!
    authenticate_request! unless @current_user
    return if @current_user.admin?

    raise NotAuthorizedError,
          t("api.v1.base_controller.errors.admins_only")
  end

  def set_locale
    header_locale = request.headers["Accept-Language"]&.scan(/^[a-z]{2}/)&.first
    I18n.locale = header_locale || I18n.default_locale
  end

  protected

  def handle_authentication_error exception
    render_error(exception.message, :unauthorized)
  end

  def handle_authorization_error exception
    render_error(exception.message, :forbidden)
  end

  def handle_not_found exception
    render_error(exception.message, :not_found)
  end

  def render_error message, status
    render json: {error: message}, status:
  end

  def render_success data, status
    render json: data, status:
  end

  def pagy_metadata pagy_object
    {
      current_page: pagy_object.page,
      next_page: pagy_object.next,
      prev_page: pagy_object.prev,
      total_pages: pagy_object.pages,
      total_count: pagy_object.count
    }
  end

  def render_paginated_response records, serializer, message =
  t("api.v1.base_controller.success")
    render json: {
      message:,
      data: ActiveModelSerializers::SerializableResource.new(
        records,
        each_serializer: serializer
      ),
      pagy: pagy_metadata(@pagy)
    }, status: :ok
  end
end
