# packs/identity/app/controllers/identity/magic_links_controller.rb
module Identity
  class MagicLinksController < ApplicationController
    def authenticate

      # Extract metadata from the request object
      metadata = {
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }

      result = ::Identity::AuthorizeLoginAttempt.call(params[:token], metadata)
      render json: result.payload, status: result.success? ? :ok : :unauthorized
    end
  end
end

