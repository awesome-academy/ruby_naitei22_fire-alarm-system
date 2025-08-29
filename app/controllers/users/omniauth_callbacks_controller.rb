class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Authentication::CookieHelpers

  skip_before_action :verify_authenticity_token, only: [:google_oauth2]

  def google_oauth2
    auth = request.env["omniauth.auth"]
    return render_auth_data_not_found unless auth

    account = find_or_initialize_account(auth)
    result = generate_tokens(account, auth)

    unless result.success?
      return render_popup_message({success: false, error: result.errors})
    end

    set_auth_cookies(result.tokens)
    render_success(result.user, result.tokens)
  end

  private

  def render_auth_data_not_found
    render_popup_message({
                           success: false,
                           error: t("google_callback.auth_data_not_found")
                         })
  end

  def find_or_initialize_account auth
    OauthAccount.find_or_initialize_by(provider: auth.provider, uid: auth.uid)
  end

  def generate_tokens account, auth
    if account.user.present?
      generate_for_existing_user(account)
    else
      generate_for_new_user(auth)
    end
  end

  def generate_for_existing_user account
    tokens = Authentication::TokenGeneratorService.new(account.user).call
    OpenStruct.new(success?: true, tokens:, user: account.user)
  end

  def generate_for_new_user auth
    signup_result = Authentication::GoogleSignupService.new(auth:).call
    return signup_result unless signup_result.success?

    tokens = Authentication::TokenGeneratorService.new(signup_result.user).call
    OpenStruct.new(success?: true, tokens:, user: signup_result.user)
  end

  def render_success user, tokens
    render_popup_message({
                           success: true,
                           access_token: tokens[:access_token],
                           refresh_token: tokens[:refresh_token],
                           user: {
                             id: user.id,
                             email: user.email,
                             name: user.name,
                             role: user.role
                           }
                         })
  end

  # rubocop:disable Rails/OutputSafety
  def render_popup_message data
    frontend_url = ENV["FRONTEND_URL"]

    render html: <<~HTML.html_safe and return
      <script>
        window.opener.postMessage(#{data.to_json}, "#{frontend_url}");
        window.close();
      </script>
    HTML
  end
  # rubocop:enable Rails/OutputSafety
end
