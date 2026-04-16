module Identity
  class LogoutUser < ::Core::BaseService
    attr_reader :refresh_token

    def initialize(refresh_token)
      @refresh_token = refresh_token
    end

    def call
      return failure("Token missing") if refresh_token.blank?

      digest = Digest::SHA256.hexdigest(refresh_token)
      session = ::Identity::Session.find_by(token_digest: digest)

      if session&.destroy
        success(message: "Logged out successfully")
      else
        failure("Session not found")
      end
    end
  end
end
