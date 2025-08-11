module Invitations
  class CreationService
    Result = Struct.new(:success?, :invitation, :errors, keyword_init: true)

    def initialize creator:
      @creator = creator
    end

    def call
      invitation = @creator.invitations.new(
        purpose: Invitation::PURPOSE_SIGNUP,
        expires_at: Invitation::DEFAULT_EXPIRATION.from_now
      )

      if invitation.save
        Result.new(success?: true, invitation:)
      else
        Result.new(success?: false,
                   errors: invitation.errors.full_messages)
      end
    end
  end
end
