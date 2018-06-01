module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user
 
    def connect
      self.current_user = find_verified_user
    end
 
    private
      def find_verified_user
        if request.params["username"]
          # API
          if current_user = User.find_by(username: request.params["username"], authentication_token: request.params["authentication_token"])
            current_user
          else
            reject_unauthorized_connection
          end
        else
          # RidePilot UI
          if current_user = env['warden'].user 
            current_user
          else
            reject_unauthorized_connection
          end
        end
      end
  end
end
