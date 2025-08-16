class Api::V1::SensorLogsController < Api::V1::BaseController
  before_action :authenticate_request!
  before_action :authorize_admin!
  before_action :set_log, only: [:show, :destroy]
  before_action :validate_sensor_ids, only: [:chart]
  before_action :parse_time_params_before_action, only: [:chart]
  DEFAULT_LOGS_LIMIT = 50
  # GET /logs/stats
  def stats
    stats = SensorLogs::LogService.new.get_stats
    render json: stats, status: :ok
  end

  # GET /logs/chart
  def chart
    chart_data = SensorLogs::LogService.new.get_chart_data(
      @sensor_ids,
      @start_time,
      @end_time
    )
    render json: chart_data, status: :ok
  end

  # GET /logs
  def index
    log_scope = SensorLog.includes(:sensor).newest
    @pagy, logs = pagy(log_scope, items: params[:limit] || DEFAULT_LOGS_LIMIT)
    render_paginated_response(logs, LogSerializer, t(".success"))
  end

  # GET /logs/:id
  def show
    render json: @log, serializer: LogSerializer, status: :ok
  end

  # DELETE /logs/:id
  def destroy
    if @log.destroy
      render json: {
        message: t(".deleted"),
        deleted_log: LogSerializer.new(@log).as_json
      }, status: :ok
    else
      render json: {errors: @log.errors.full_messages},
             status: :unprocessable_entity
    end
  end

  private

  def set_log
    @log = SensorLog.includes(:sensor).find_by(id: params[:id])
    return if @log

    render json: {errors: [t(".not_found")]}, status: :not_found
  end

  def validate_sensor_ids
    sensor_ids_param = params[:sensorIds] || params[:sensor_ids]
    @sensor_ids = sensor_ids_param&.split(",") || []

    return unless @sensor_ids.empty?

    render json: {error: t(".cant_find_sensorid")}, status: :bad_request
  end

  def parse_time_params_before_action
    start_time_param = params[:startTime]
    end_time_param   = params[:endTime]

    @start_time, @end_time = parse_time_params(start_time_param, end_time_param)
    head(:unprocessable_entity) if performed?
  end

  def parse_time_params start_time_param, end_time_param
    start_time = Time.zone.parse(start_time_param) if start_time_param.present?
    end_time   = Time.zone.parse(end_time_param) if end_time_param.present?
    [start_time, end_time]
  rescue ArgumentError
    render json: {error: t("errors.invalid_time_format")},
           status: :unprocessable_entity
    nil
  end
end
