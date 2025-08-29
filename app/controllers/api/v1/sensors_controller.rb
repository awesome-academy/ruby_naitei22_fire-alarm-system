class Api::V1::SensorsController < Api::V1::BaseController
  before_action :authenticate_request!
  before_action :load_sensor, only: [:show, :update, :destroy]
  before_action :authorize_admin!, only: [:destroy]
  load_and_authorize_resource
  # GET /api/sensors/stats
  def stats
    authorize! :stats, Sensor
    stats = Sensors::SensorService.new.get_stats
    render json: stats
  end

  # POST /api/sensors
  def create
    if @sensor.save
      render_success(
        {message: t(".success"), sensor: SensorSerializer.new(@sensor)},
        :created
      )
    else
      render_error(sensor.errors.full_messages, :unprocessable_entity)
    end
  end

  # POST /api/sensors/bulk
  def bulk
    authorize! :bulk, Sensor
    permitted_sensors = params.require(:sensors).map do |sensor|
      sensor.permit(*Sensor::SENSOR_PERMITTED)
    end

    result = Sensors::SensorService.new.bulk(permitted_sensors)

    render json: {
      message: t(".success", count: result[:inserted]),
      inserted: result[:inserted]
    }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: {message: t(".error"), error: e.record.errors.full_messages},
           status: :unprocessable_entity
  end

  # GET /api/sensors
  def index
    sensor_scope = @sensors.includes(:zone)
    @pagy, sensors = pagy(sensor_scope,
                          items: params[:limit] || Settings.digits.digit_20)
    render_paginated_response(sensors, SensorSerializer, t(".success"))
  end

  # GET /api/sensors/:id
  def show
    render json: @sensor, serializer: SensorSerializer
  end

  # PATCH/PUT /api/sensors/:id
  def update
    if @sensor.update(sensor_params)
      render_success(
        {message: t(".success"), sensor: SensorSerializer.new(@sensor)},
        :ok
      )
    else
      render_error(@sensor.errors.full_messages, :unprocessable_entity)
    end
  end

  # DELETE /api/sensors/:id
  def destroy
    if @sensor.destroy
      render_success({message: t(".success"), sensor: @sensor}, :ok)
    else
      render json: {errors: @sensor.errors.full_messages},
             status: :unprocessable_entity
    end
  end

  private

  def sensor_params
    params.require(:sensor).permit(Sensor::SENSOR_PERMITTED)
  end
end
