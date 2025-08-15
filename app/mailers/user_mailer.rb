class UserMailer < ApplicationMailer
  default from: ENV.fetch("MAILER_SENDER_ADDRESS")

  def password_reset user
    @user = user
    @reset_url = @user.forgot_pw_url
    mail(
      to: @user.email,
      subject: I18n.t("user_mailer.password_reset.subject")
    )
  end
end
