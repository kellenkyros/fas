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

      # 1. user.authenticate now looks into the `credentials` table (as refactored previously)
      if user&.authenticate(password)
        # 2. Generate short-lived Access Token (JWT)
        access_token = JWT.encode({
          user_id: user.id,
          exp: 1.hour.from_now.to_i
        }, SECRET_KEY)

        # 3. Create long-lived Refresh Token (Session)
        raw_refresh_token = SecureRandom.hex(64)

        # Create a record in our new dedicated sessions table
        user.sessions.create!(
          token_digest: Digest::SHA256.hexdigest(raw_refresh_token),
          ip_address: metadata[:ip_address],
          user_agent: metadata[:user_agent],
          expires_at: 30.days.from_now
        )
        success(access_token: access_token, refresh_token: raw_refresh_token)
      else
        failure('Invalid email or password')
      end
    end
  end
end
