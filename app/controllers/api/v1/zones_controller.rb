class Api::V1::ZonesController < Api::V1::BaseController
  before_action :set_zone, only: [:show, :update, :destroy]

  # GET /api/v1/zones
  def index
    @zones = Zone.all
    render json: {
      message: t("zones.index.success"),
      data: @zones
    }
  end

  # GET /api/v1/zones/:id
  def show
    render json: {
      message: t("zones.show.success"),
      data: @zone
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
    @zone.destroy
    head :no_content
  end

  private

  def set_zone
    @zone = Zone.find(params[:id])
  end

  def zone_params
    params.require(:zone).permit(:name, :description, :city, :latitude,
                                 :longitude, :user_id)
  end
end
