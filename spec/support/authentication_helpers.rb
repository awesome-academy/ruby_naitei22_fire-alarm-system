module AuthenticationHelpers
    def login_as(user)
        access_token = Authentication::TokenGeneratorService.new(user).send(:generate_access_token)
        cookies[:accessToken] = access_token
    end

    def logout
        cookies.delete(:accessToken)
    end
end

RSpec.configure do |config|
    config.include AuthenticationHelpers, type: :request
end
