module Identity
  class RefreshToken < ::Core::BaseService
    SECRET_KEY = Rails.application.credentials.secret_key_base

    attr_reader :raw_refresh_token

    def initialize(raw_refresh_token)
      @raw_refresh_token = raw_refresh_token
    end

    def call
      return failure('Token missing') if raw_refresh_token.blank?

      # 1. Find the session using the hashed token
      session = find_valid_session

      if session
        # 2. Perform Refresh Token Rotation (RTR)
        new_raw_token = refresh_token(session)

        # 3. Generate new short-lived access token
        access_token = generate_access_token(session.user)

        success(
          access_token: access_token,
          refresh_token: new_raw_token
        )
      else
        failure('Session expired or invalid')
      end
    rescue ActiveRecord::RecordNotFound
      failure('User no longer exists')
    end

    private

    def find_valid_session
      digest = Digest::SHA256.hexdigest(raw_refresh_token)
      # Using .where.first allows us to chain the expiration check easily
      ::Identity::Session.where(token_digest: digest)
                         .where('expires_at > ?', Time.current)
                         .first
    end

    def refresh_token(session)
      new_raw = SecureRandom.hex(64)
      session.update!(
        token_digest: Digest::SHA256.hexdigest(new_raw),
        expires_at: 30.days.from_now
      )
      new_raw
    end

    def generate_access_token(user)
      JWT.encode(
        { user_id: user.id, exp: 15.minutes.from_now.to_i },
        SECRET_KEY
      )
    end
  end
end
