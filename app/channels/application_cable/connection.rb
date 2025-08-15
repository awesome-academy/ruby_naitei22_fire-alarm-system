module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
      logger.add_tags "ActionCable", "User #{current_user.id}" if current_user
    end

    private

    def find_verified_user
      token = cookies[:accessToken]
      if token.present?
        begin
          decoded_token = Authentication::JsonWebToken.decode(token)
          verified_user = User.find_by(id: decoded_token["sub"])
          verified_user || reject_unauthorized_connection
        rescue JWT::DecodeError
          reject_unauthorized_connection
        end
      else
        reject_unauthorized_connection
      end
    end
  end
end
