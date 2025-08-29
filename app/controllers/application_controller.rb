class ApplicationController < ActionController::Base
  include Pagy::Backend
  protect_from_forgery with: :null_session
  rescue_from CanCan::AccessDenied do |exception|
    render json: {
      error: I18n.t("cancan.access_denied"),
      action: exception.action,
      subject: exception.subject
    }, status: :forbidden
  end
end
