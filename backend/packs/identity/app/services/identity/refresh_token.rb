module Identity
  class RefreshToken < ::Core::BaseService
    SECRET_KEY = Rails.application.credentials.secret_key_base

    attr_reader :raw_refresh_token

    def initialize(raw_refresh_token, metadata)
      @raw_refresh_token = raw_refresh_token
      @metadata = metadata
    end

    def call
      return failure('Token missing') if raw_refresh_token.blank?

      # 1. Find the session using the hashed token
      session = find_valid_session

      if session
        result = Identity::GenerateUserSession.call(user: session.user, metadata: @metadata)
        if result.success?
          success(result.data)
        else
          failure("Session generation failed")
        end
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
  end
end

