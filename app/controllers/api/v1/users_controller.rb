# frozen_string_literal: true

class Api::V1::UsersController < Api::V1::BaseController
  UPDATE_PARAMS_PERMIT = %i(name phone address is_active).freeze

  before_action :authenticate_request!
  load_and_authorize_resource

  # GET /api/v1/users
  def index
    ransack_params = if params[:q].is_a?(String) && params[:q].present?
                       JSON.parse(params[:q])
                     else
                       params[:q]
                     end
    @q = @users.ransack(ransack_params)

    users_scope = @q.result(distinct: true).newest
    @pagy, users = pagy(users_scope)
    render_paginated_response(users, UserSerializer, t(".success"))
  end

  # GET /api/v1/users/:id
  def show
    render json: @user, serializer: UserSerializer, status: :ok
  end

  # PATCH /api/v1/users/:id
  def update
    if @user.update(update_params)
      render_success(
        {
          message: t("api.v1.users.update.success"),
          user: UserSerializer.new(@user)
        },
        :ok
      )
    else
      render_error(@user.errors.full_messages, :unprocessable_entity)
    end
  end

  private

  def update_params
    permitted_params = params.key?(:user) ? params.require(:user) : params
    permitted_params.permit(UPDATE_PARAMS_PERMIT)
  end
end
