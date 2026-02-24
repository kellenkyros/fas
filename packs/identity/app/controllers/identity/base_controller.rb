# packs/identity/app/controllers/identity/base_controller.rb
module Identity
  class BaseController < ::ApplicationController
    def authenticate_request
      header = request.headers["Authorization"]
      token = header.split(" ").last if header

      begin
        secret = Rails.application.credentials.secret_key_base
        decoded = JWT.decode(token, secret)[0]
        @current_user_id = decoded["user_id"]
      rescue JWT::ExpiredSignature
        # Explicitly tell the frontend the token is expired, not just "bad"
        render json: { errors: [ "Token expired" ] }, status: :unauthorized
      rescue JWT::DecodeError
        render json: { errors: [ "Invalid token" ] }, status: :unauthorized
      rescue NameError
        render json: { errors: [ "Server configuration error" ] }, status: :internal_server_error
      end
    end
  end
end
