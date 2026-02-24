# packs/identity/app/services/identity/authorize_login_attempt.rb
module Identity
  class AuthorizeLoginAttempt < ::Core::BaseService
    def initialize(token)
      @token = token
    end

    def call
      attempt = LoginAttempt.find_by(magic_token: @token, status: :pending)
      return failure("Invalid Link") unless attempt

      access_token = SecureRandom.hex(40)

      if attempt.update(status: :authorized, access_token: access_token)
        # Broadcast the success to Solid Cable
        ::Core::EventBus.publish("login_#{attempt.external_id}", {
          token: access_token,
          status: "success"
        })
        success(attempt)
      else
        failure(attempt.errors.full_messages)
      end
    end
  end
end
