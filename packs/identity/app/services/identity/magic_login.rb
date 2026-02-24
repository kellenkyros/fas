module Identity
  class MagicLogin < ::Core::BaseService
    SECRET_KEY = Rails.application.credentials.secret_key_base

    attr_reader :token, :metadata

    def initialize(token, metadata = {})
      @token = token
      @metadata = metadata
    end

    def call
      # Use Ruby's native begin/rescue instead of catch/throw for cleaner logic
      user = ::Identity::User.find_signed!(token, purpose: :magic_link)

      # If we reach here, the token is valid
      access_token = generate_access_token(user)
      raw_refresh_token = create_session(user)

      success(
        access_token: access_token,
        refresh_token: raw_refresh_token
      )
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
      # The find_signed! method raises an error if the token is bad or expired
      failure('Invalid or Expired Link')
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
