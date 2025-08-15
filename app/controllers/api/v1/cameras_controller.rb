# frozen_string_literal: true

class Api::V1::CamerasController < Api::V1::BaseController
  before_action :authenticate_request!
  before_action :authorize_admin!
  before_action :set_camera,
                only: %i(show update destroy capture_and_upload_snapshot)

  # GET /api/v1/cameras
  def index
    @pagy, cameras = pagy(Camera.includes(:zone).newest)
    render_paginated_response(cameras, CameraSerializer, t(".success"))
  end

  # GET /api/v1/cameras/stats
  def stats
    total_count = Camera.count
    render_success({total: total_count}, :ok)
  end

  # GET /api/v1/cameras/:id
  def show
    render json: @camera, serializer: CameraSerializer, status: :ok
  end

  # POST /api/v1/cameras
  def create
    camera = Camera.new(camera_params)
    if camera.save
      render_success(
        {
          message: t(".success"),
          camera: CameraSerializer.new(camera)
        },
        :created
      )
    else
      render_error(camera.errors.full_messages, :unprocessable_entity)
    end
  end

  # PATCH /api/v1/cameras/:id
  def update
    if @camera.update(camera_params)
      render_success(
        {
          message: t(".success"),
          camera: CameraSerializer.new(@camera)
        },
        :ok
      )
    else
      render_error(@camera.errors.full_messages, :unprocessable_entity)
    end
  end

  # DELETE /api/v1/cameras/:id
  def destroy
    if @camera.destroy
      render_success({message: t(".success")}, :ok)
    else
      render_error(@camera.errors.full_messages, :unprocessable_entity)
    end
  end

  # POST /api/v1/cameras/:id/capture_and_upload_snapshot
  def capture_and_upload_snapshot
    result = Cameras::SnapshotService.new(camera: @camera).call

    if result.success?
      render_success(
        {
          message: t(".success"),
          snapshot_url: result.camera.last_snapshot_url,
          camera: CameraSerializer.new(result.camera)
        },
        :ok
      )
    else
      status = result.status_code || :internal_server_error
      render_error(result.error, status)
    end
  end

  private

  def set_camera
    @camera = Camera.find_by(id: params[:id])
    return if @camera

    raise ActiveRecord::RecordNotFound,
          t("api.v1.cameras.not_found",
            id: params[:id])
  end

  def camera_params
    params.require(:camera).permit(Camera::CAMERA_PERMIT)
  end
end
