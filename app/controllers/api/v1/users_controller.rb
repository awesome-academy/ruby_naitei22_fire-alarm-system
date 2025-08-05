# frozen_string_literal: true

class Api::V1::UsersController < Api::V1::BaseController
  UPDATE_PARAMS_PERMIT = %i(name phone address).freeze

  before_action :authenticate_request!
  before_action :load_user, only: %i(show update)
  before_action :authorize_admin!, only: :index
  before_action :authorize_update!, only: :update

  # GET /api/v1/users
  def index
    @pagy, users = pagy(User.all.newest)
    render json: {
      users: ActiveModelSerializers::SerializableResource.new(
        users, each_serializer: UserSerializer
      ),
      pagy: pagy_metadata(@pagy)
    }, status: :ok
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
    params.require(:user).permit(UPDATE_PARAMS_PERMIT)
  end

  def load_user
    @user = User.find_by(id: params[:id])
    raise ActiveRecord::RecordNotFound, t("api.v1.users.not_found") unless @user
  end

  def authorize_update!
    is_current_user = (@user.id == @current_user.id)
    is_admin = @current_user.admin?
    return if is_current_user || is_admin

    raise NotAuthorizedError,
          t("api.v1.users.not_authorized")
  end
end
