module Identity
  class UsersController < BaseController
    def signup
      ::Identity::RegisterUser.call(user_params) do |result|
        result.on_success do |user|
          return render json: { message: "Success", user: { email: user.email } }, status: :created
        end

        result.on_failure do |errors|
          return render json: { errors: errors }, status: :unprocessable_entity
        end
      end
    end

    private

    def user_params
      # This permits the flat params or the wrapped :user params
      params.require(:user).permit(:email, :password, :password_confirmation) rescue params.permit(:email, :password, :password_confirmation)
    end
  end
end
