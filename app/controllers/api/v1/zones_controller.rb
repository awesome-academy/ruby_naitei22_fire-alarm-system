# frozen_string_literal: true

class Api::V1::ZonesController < Api::V1::BaseController
  before_action :authenticate_request!
  load_and_authorize_resource
  PERMIT = %i(name description city latitude longitude user_id).freeze

  # GET /api/v1/zones
  def index
    ransack_params = if params[:q].is_a?(String) && params[:q].present?
                       JSON.parse(params[:q])
                     else
                       params[:q]
                     end
    @q = @zones.ransack(ransack_params)

    zones_scope = @q.result(distinct: true)
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
    unless current_user.admin? && zone_params[:user_id].present?
      @zone.user = current_user
    end

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
