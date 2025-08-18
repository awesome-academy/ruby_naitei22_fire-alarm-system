# frozen_string_literal: true

class Api::V1::AlertsController < Api::V1::BaseController
  before_action :authenticate_request!
  before_action :authorize_admin!, only: %i(index show create stats)
  before_action :set_alert, only: %i(show update_status)
  DEFAULT_PER_PAGE = 10

  # GET /api/v1/alerts
  def index
    alerts_scope = Alert.includes(Alert::ALERTS_PRELOAD).newest
    alerts_scope = alerts_scope.with_status(params[:status])
    alerts_scope = alerts_scope.in_date_range(params[:start_date],
                                              params[:end_date])

    items_per_page = params.fetch(:limit, DEFAULT_PER_PAGE).to_i
    @pagy, alerts = pagy(alerts_scope, items: items_per_page)

    render_paginated_response(alerts, AlertSerializer, t(".success"))
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
