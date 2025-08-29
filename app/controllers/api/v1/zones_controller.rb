class Api::V1::ZonesController < Api::V1::BaseController
  PERMIT = %i(name description city latitude longitude).freeze

  before_action :authenticate_request!
  load_and_authorize_resource except: [:index, :create], class: "Zone"

  # GET /api/v1/zones
  def index
    zones_scope = Zone.filter_and_sort(params)
    if @current_user.supervisor?
      zones_scope = zones_scope.where(user_id: @current_user.id)
    end

    @pagy, zones = pagy(zones_scope)
    render_paginated_response(zones, ZoneSerializer, t(".success"))
  end

  # GET /api/v1/zones/:id
  def show
    render_success({message: t(".success"), data: ZoneSerializer.new(@zone)},
                   :ok)
  end

  # POST /api/v1/zones
  def create
    @zone = current_user.zones.new(zone_params)
    authorize! :create, @zone

    if @zone.save
      render_success(
        {message: t(".success"), data: ZoneSerializer.new(@zone)}, :created
      )
    else
      render_error(@zone.errors.full_messages, :unprocessable_entity)
    end
  end

  # PUT/PATCH /api/v1/zones/:id
  def update
    if @zone.update(zone_params)
      render_success(
        {message: t(".success"), data: ZoneSerializer.new(@zone)}, :ok
      )
    else
      render_error(@zone.errors.full_messages, :unprocessable_entity)
    end
  end

  # DELETE /api/v1/zones/:id
  def destroy
    if @zone.destroy
      render_success({message: t(".success")}, :ok)
    else
      render_error(@zone.errors.full_messages, :unprocessable_entity)
    end
  end

  private

  def zone_params
    params.require(:zone).except(:id).permit(*PERMIT)
  end
end
