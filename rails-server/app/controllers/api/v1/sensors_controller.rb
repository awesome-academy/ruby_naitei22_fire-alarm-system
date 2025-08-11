class Api::V1::SensorsController < Api::V1::BaseController
  before_action :authenticate_request!
  before_action :load_sensor, only: [:show, :update, :destroy]
  before_action :authorize_admin!, only: [:destroy]

  # GET /api/sensors/stats
  def stats
    stats = Sensors::SensorService.new.get_stats
    render json: stats
  end

  # POST /api/sensors
  def create
    sensor = Sensor.new(sensor_params)
    if sensor.save
      render_success(
        {
          message: t(".success"),
          sensor: SensorSerializer.new(sensor)
        },
        :created
      )
    else
      render_error(sensor.errors.full_messages, :unprocessable_entity)
    end
  end

  # POST /api/sensors/bulk
  def bulk
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
    sensor_scope = Sensors::SensorService.new.find_all(
      params.permit(Sensor::SENSOR_INDEX_PERMITTED)
    )

    @pagy, sensors = pagy(sensor_scope,
                          items: params[:limit] || Settings.digits.digit_20)

    render_success(
      {
        message: t(".success"),
        sensors: ActiveModelSerializers::SerializableResource.new(
          sensors, each_serializer: SensorSerializer
        ),
        pagy: pagy_metadata(@pagy)
      },
      :ok
    )
  end

  # GET /api/sensors/:id
  def show
    render json: @sensor, serializer: SensorSerializer
  end

  # PATCH/PUT /api/sensors/:id
  def update
    if @sensor.update(sensor_params)
      render_success(
        {
          message: t(".success"),
          sensor: SensorSerializer.new(@sensor)
        },
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

  def load_sensor
    @sensor = Sensor.find_by(id: params[:id])
    return if @sensor.present?

    render json: {error: t(".sensor_not_found")}, status: :not_found
  end

  def sensor_params
    params.require(:sensor).permit Sensor::SENSOR_PERMITTED
  end

  def authorize_admin!
    return if current_user&.admin?

    render json: {error: t(".forbidden")},
           status: :forbidden
  end
end
