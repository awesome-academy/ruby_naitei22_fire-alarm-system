module Invitations
  class CreationService
    Result = Struct.new(:success?, :invitation, :errors, keyword_init: true)

    def initialize creator:, email:
      @creator = creator
      @email = email
    end

    def call
      invitation = @creator.invitations.new(
        email: @email,
        purpose: Invitation::PURPOSE_SIGNUP,
        expires_at: Invitation::DEFAULT_EXPIRATION.from_now
      )

      if invitation.save
        InvitationMailer.invitation(invitation).deliver_later
        Result.new(success?: true, invitation:)
      else
        Result.new(success?: false, errors: invitation.errors.full_messages)
      end
    end
  end
end
