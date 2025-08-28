module Authentication
  class GoogleSignupService
    Result = Struct.new(:success?, :user, :errors, keyword_init: true)

    def initialize auth:
      @auth = auth
    end

    def call
      return invalid_invitation_result unless valid_invitation?

      begin
        ActiveRecord::Base.transaction do
          create_user_and_account
        end
      rescue ActiveRecord::ActiveRecordError => e
        Result.new(success?: false, errors: e.message)
      end
    end

    private

    def valid_invitation?
      @invitation = Invitation.find_by(
        email: @auth.info.email,
        purpose: Invitation::PURPOSE_SIGNUP
      )
      @invitation&.expires_at&.future? && @invitation.used == false
    end

    def invalid_invitation_result
      Result.new(
        success?: false,
        errors: I18n.t("google_callback.invitation_invalid")
      )
    end

    def create_user_and_account
      user = User.new(
        email: @auth.info.email,
        name: @auth.info.name,
        password: Devise.friendly_token[0, 20],
        role: :supervisor,
        is_active: true,
        admin_id: @invitation.user_id
      )

      if user.save
        attach_oauth_account(user)
        @invitation.update!(used: true, user:)
        Result.new(success?: true, user:)
      else
        Result.new(success?: false, errors: user.errors.full_messages)
      end
    end

    def attach_oauth_account user
      account = OauthAccount.find_or_initialize_by(
        provider: @auth.provider,
        uid: @auth.uid
      )
      account.update!(user:)
    end
  end
end
