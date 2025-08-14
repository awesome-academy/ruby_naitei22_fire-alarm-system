class Api::V1::ZonesController < Api::V1::BaseController
  PERMIT = %i(name description city latitude longitude user_id).freeze
  before_action :set_zone, only: [:show, :update, :destroy]

  # GET /api/v1/zones
  def index
    @zones = if params[:sort] == "name"
               Zone.sorted_by_name
             else
               Zone.all
             end

    render json: {
      message: t("zones.index.success"),
      data: @zones.as_json(include: [:cameras, :sensors])
    }
  end

  # GET /api/v1/zones/:id
  def show
    render json: {
      message: t("zones.show.success"),
      data: @zone.as_json(include: [:cameras, :sensors])
    }
  end

  # POST /api/v1/zones
  def create
    @zone = Zone.new(zone_params)
    if @zone.save
      render json: {
        message: t("zones.create.success"),
        data: @zone
      }, status: :created
    else
      render json: {
        message: t("zones.create.failure"),
        data: @zone.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /api/v1/zones/:id
  def update
    if @zone.update(zone_params)
      render json: {
        message: t("zones.update.success"),
        data: @zone
      }
    else
      render json: {
        message: t("zones.update.failure"),
        data: @zone.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy
    if @zone.destroy
      render json: {
        message: t("zones.destroy.success"),
        data: @zone
      }, status: :ok
    else
      render json: {
        message: t("zones.destroy.failure"),
        data: @zone.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_zone
    @zone = Zone.find_by(id: params[:id])

    return if @zone

    render json: {
      message: t("zones.errors.not_found"),
      data: nil
    }, status: :not_found
  end

  def zone_params
    params.require(:zone).permit(*PERMIT)
  end
end
