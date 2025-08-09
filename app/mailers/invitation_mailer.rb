class InvitationMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_SENDER_ADDRESS")

  def invitation invitation
    @invitation = invitation
    @creator = @invitation.user
    @signup_url = @invitation.signup_url

    mail(to: @invitation.email,
         subject: t(".subject", creator_name: @creator.name))
  end
end
