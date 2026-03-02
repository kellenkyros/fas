module Identity
  class GenerateUserSession < Core::BaseService
    attr_reader :user, :metadata

    SECRET_KEY = Rails.application.credentials.secret_key_base

    def initialize(user:, metadata:)
      @user = user
      @metadata = metadata
    end

    def call
      # 1. Generate the JWT Access Token
      access_token = generate_access_token(user)

      # 2. Generate a long-lived Refresh Token
      # Stored in DB to allow revocation/refreshing
      refresh_token = create_session(user)

      success({
        access_token: access_token,
        refresh_token: refresh_token,
      })
    rescue => e
      failure(e.message)
    end

    private

    def generate_access_token(user)
      JWT.encode({
        user_id: user.id,
        exp: 1.hour.from_now.to_i
      }, SECRET_KEY)
    end

    def create_session(user)
      raw_token = SecureRandom.hex(64)
      user.sessions.create!(
        token_digest: Digest::SHA256.hexdigest(raw_token),
        ip_address: metadata[:ip_address],
        user_agent: metadata[:user_agent],
        expires_at: 30.days.from_now
      )
      raw_token
    end
  end
end
