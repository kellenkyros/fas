module Identity
  class ChangePassword < ::Core::BaseService
    attr_reader :user_id, :password_params

    def initialize(user_id, password_params)
      @user_id = user_id
      @password_params = password_params
    end

    def call
      user = ::Identity::User.find_by(id: user_id)

      return failure("Invalid User") unless user

      # 2. Find the existing password credential or build a new one
      credential = user.credentials.find_or_initialize_by(cred_type: 'password')

      # 3. Assign the new password (assuming your Credential model handles BCrypt)
      credential.password = password_params[:password]
      credential.password_confirmation = password_params[:password_confirmation]

      if credential.save
        success
      else
        failure(credential.errors.full_messages)
      end
    end
  end
end
