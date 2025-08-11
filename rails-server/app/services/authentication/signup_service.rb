# frozen_string_literal: true

module Authentication
  class SignupService
    Result = Struct.new(:success?, :user, :errors, keyword_init: true)
    SIGNUP_PERMIT = %i(name email phone password invitation_code).freeze

    def initialize params
      @params = strong_params(params)
      @invitation_code = @params[:invitation_code]
    end

    def call
      invitation = find_valid_invitation
      return invitation_error unless invitation

      user = build_user_from_invitation(invitation)

      if save_user_and_mark_invitation_used(user, invitation)
        Result.new(success?: true, user:)
      else
        Result.new(success?: false, errors: user.errors.full_messages)
      end
    end

    private

    attr_reader :params, :invitation_code

    def strong_params raw_params
      raw_params.permit(SIGNUP_PERMIT)
    end

    def find_valid_invitation
      Invitation.valid_for_signup.find_by(code: invitation_code)
    end

    def build_user_from_invitation invitation
      User.new(
        name: params[:name],
        email: params[:email],
        phone: params[:phone],
        password: params[:password],
        role: :supervisor,
        admin_id: invitation.user_id,
        is_active: true
      )
    end

    def save_user_and_mark_invitation_used user, invitation
      ActiveRecord::Base.transaction do
        user.save!
        invitation.update!(used: true)
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end

    def invitation_error
      key = "services.authentication.signup.invalid_invitation"
      error_message = I18n.t(key)
      Result.new(success?: false, errors: [error_message])
    end
  end
end
