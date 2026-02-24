module Identity
  class ProfilesController < BaseController
    # Require a valid token for every action in this controller
    before_action :authenticate_request

    def show
      ::Identity::FetchUserProfile.call(@current_user_id) do |result|
        result.on_success { |profile| render json: { data: profile }, status: :ok }
        result.on_failure { |errors| render json: { errors: errors }, status: :not_found }
      end
    end

    def change_password
      password_params = params.permit(:current_password, :password, :password_confirmation)
      ::Identity::ChangePassword.call(@current_user_id, password_params) do |result|
        result.on_success { render json: { message: "Password updated" }, status: :ok }
        result.on_failure { |errors| render json: { errors: errors }, status: :unprocessable_entity }
      end
    end
  end
end
