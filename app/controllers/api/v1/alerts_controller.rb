# frozen_string_literal: true

class Api::V1::AlertsController < Api::V1::BaseController
  ALERTS_PRELOAD = %i(user zone owner).freeze
  before_action :authenticate_request!
  before_action :authorize_admin!, only: %i(index show create stats)
  before_action :set_alert, only: %i(show update_status)

  # GET /api/v1/alerts
  def index
    alerts = Alert.includes(ALERTS_PRELOAD)
                  .with_status(params[:status])
                  .in_date_range(params[:start_date], params[:end_date])
                  .newest

    @pagy, alerts = pagy(alerts)
    render_paginated_response(alerts, AlertSerializer)
  end

  # GET /api/v1/alerts/stats
  def stats
    render_success({pending: Alert.pending_count}, :ok)
  end

  # GET /api/v1/alerts/:id
  def show
    render json: @alert, serializer: AlertSerializer, status: :ok
  end

  # POST /api/v1/alerts
  def create
    @alert = Alert.new(alert_params)
    if @alert.save
      Alerts::NotificationService.new(alert: @alert).call
      render_success(
        {message: t(".success"), alert: AlertSerializer.new(@alert)},
        :created
      )
    else
      render_error(@alert.errors.full_messages, :unprocessable_entity)
    end
  end

  # PATCH /api/v1/alerts/:id/status
  def update_status
    result = Alerts::StatusUpdaterService.new(
      alert: @alert,
      user: @current_user,
      new_status: params.require(:status)
    ).call

    if result.success?
      render_success(
        {message: t(".success"), alert: AlertSerializer.new(result.alert)},
        :ok
      )
    else
      render_error(result.errors, :unprocessable_entity)
    end
  end

  private

  def set_alert
    @alert = Alert.find_by(id: params[:id])
    raise ActiveRecord::RecordNotFound unless @alert
  end

  def alert_params
    params.require("alert").permit(Alert::ALERT_PERMIT)
  end
end
