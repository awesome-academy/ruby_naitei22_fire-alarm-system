class Api::V1::ZonesController < Api::V1::BaseController
  before_action :authenticate_request!
  load_and_authorize_resource
  PERMIT = %i(name description city latitude longitude).freeze
  # GET /api/v1/zones
  def index
    zones_scope = @zones.filter_and_sort(params)

    @pagy, zones = pagy(zones_scope)
    render_paginated_response(zones, ZoneSerializer, t(".success"))
  end

  # GET /api/v1/zones/:id
  def show
    render_success({
                     message: t(".success"),
                     data: ZoneSerializer.new(@zone)
                   }, :ok)
  end

  # POST /api/v1/zones
  def create
    @zone.user = current_user
    if @zone.save
      render_success({
                       message: t(".success"),
                       data: ZoneSerializer.new(@zone)
                     }, :created)
    else
      render_error(@zone.errors.full_messages, :unprocessable_entity)
    end
  end

  # PUT/PATCH /api/v1/zones/:id
  def update
    if @zone.update(zone_params)
      render_success({
                       message: t(".success"),
                       data: ZoneSerializer.new(@zone)
                     }, :ok)
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
    params.require(:zone).permit(*PERMIT)
  end
end
