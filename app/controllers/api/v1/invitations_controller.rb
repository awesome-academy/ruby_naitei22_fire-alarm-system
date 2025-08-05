# frozen_string_literal: true

class Api::V1::InvitationsController < Api::V1::BaseController
  before_action :authenticate_request!
  before_action :authorize_admin!

  # GET /api/v1/invitations
  def index
    invitations = @current_user.invitations.newest
    render json: invitations, each_serializer: InvitationSerializer, status: :ok
  end

  # POST /api/v1/invitations
  def create
    result = Invitations::CreationService.new(creator: @current_user).call
    unless result.success?
      return render_error(result.errors, :unprocessable_entity)
    end

    render_success(
      {
        message: t("api.v1.invitations.create.success"),
        invitation: InvitationSerializer.new(result.invitation)
      },
      :created
    )
  end
end
