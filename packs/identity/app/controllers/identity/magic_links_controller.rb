# packs/identity/app/controllers/identity/magic_links_controller.rb
module Identity
  class MagicLinksController < ApplicationController
    def authenticate
      result = ::Identity::AuthorizeLoginAttempt.call(params[:token])
      render json: result.payload, status: result.success? ? :ok : :unauthorized
    end
  end
end

