# packs/identity/app/services/identity/authorize_login_attempt.rb
module Identity
  class AuthorizeLoginAttempt < ::Core::BaseService
    def initialize(token, metadata)
      @token = token
      @metadata = metadata
    end

    def call
      attempt = LoginAttempt.find_by(magic_token: @token, status: :pending)
      return failure("Invalid Link") unless attempt
      
      result = Identity::GenerateUserSession.call(user: attempt.user, metadata: @metadata)
      if result.success?
        attempt.update!(status: :authorized)

        # Broadcast to Solid Cable / EventBus
        ::Core::EventBus.publish("login_#{attempt.external_id}", {
          status: "success",
          token: result.data[:access_token],       # Valid JWT
          refresh_token: result.data[:refresh_token] # For persistent sessions
        })

        success(attempt)
      else
        failure("Session generation failed")
      end
    end
  end
end
