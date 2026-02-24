module Identity
  class SessionsController < BaseController
    def create
      # Extract metadata from the request object
      metadata = {
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
      ::Identity::AuthenticateUser.call(params[:email], params[:password], metadata: metadata) do |result|
        result.on_success { |data| render json: result.payload, status: :ok }
        result.on_failure { |errors| render json: result.payload, status: :unauthorized }
      end
    end

    def refresh
      Identity::RefreshToken.call(params[:refresh_token]) do |result|
        result.on_success { |data| render json: { data: data }, status: :ok }
        result.on_failure { |errors| rendner json: { errors: errors }, status: :unauthorized }
      end
    end

    def destroy
      ::Identity::LogoutUser.call(params[:refresh_token]) do |result|
        result.on_success { |data| render json: data, status: :ok }
        result.on_failure { |errors| render json: { errors: errors }, status: :unprocessable_entity }
      end
    end

    def send_magic_login
      ::Identity::SendMagicLogin.call(params[:email]) do |result|
        result.on_success { |result| render status: :ok }
        result.on_failure { |errors| render json: { errors: errors }, status: :unauthorized }
      end
    end

    def magic_login
      # Extract metadata from the request object
      metadata = {
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
      ::Identity::MagicLogin.call(params[:token], metadata) do |result|
        result.on_success { |data| render json: data, status: :ok }
        result.on_failure { |errors| render json: { errors: errors }, status: :unauthorized }
      end
    end
  end
end
