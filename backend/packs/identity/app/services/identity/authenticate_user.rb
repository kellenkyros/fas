module Identity
  class AuthenticateUser < ::Core::BaseService
    SECRET_KEY = Rails.application.credentials.secret_key_base

    attr_reader :email, :password, :metadata

    def initialize(email, password, metadata: {})
      @email = email
      @password = password
      @metadata = metadata
    end

    def call
      user = ::Identity::User.find_by(email: email)

      if user&.authenticate(password)
        result = Identity::GenerateUserSession.call(user: user, metadata: @metadata)
        if result.success?
          success(result.data)
        else
          failure("Session generation failed")
        end
      else
        failure('Invalid email or password')
      end
    end
  end
end

