# frozen_string_literal: true

class Api::V1::AlertsController < Api::V1::BaseController
  before_action :authenticate_request!
  load_and_authorize_resource
  DEFAULT_PER_PAGE = 10

  # GET /api/v1/alerts
  def index
    alerts_scope = @alerts.includes(Alert::ALERTS_PRELOAD).newest
    alerts_scope = alerts_scope.with_status(params[:status])
    alerts_scope = alerts_scope.in_date_range(params[:start_date],
                                              params[:end_date])

    items_per_page = params.fetch(:limit, DEFAULT_PER_PAGE).to_i
    @pagy, alerts = pagy(alerts_scope, items: items_per_page)

    render_paginated_response(alerts, AlertSerializer, t(".success"))
  end

  # GET /api/v1/alerts/stats
  def stats
    authorize! :stats, Alert
    render_success({pending: Alert.pending_count}, :ok)
  end

  # GET /api/v1/alerts/:id
  def show
    render json: @alert, serializer: AlertSerializer, status: :ok
  end

  # POST /api/v1/alerts
  def create
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
    authorize! :update_status, @alert
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

  def alert_params
    params.require(:alert).permit(Alert::ALERT_PERMIT)
  end
end
