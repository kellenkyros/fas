module Identity
  class SendMagicLogin < ::Core::BaseService
    attr_reader :email

    def initialize(email)
      @email = email
    end

    def call
      user = ::Identity::User.find_by(email: email)

      if user
        # 1. Generate a secure, time-limited token
        token = generate_token(user)

        # 2. Send the email in the background
        # TODO: Use deliver_later
        ::Identity::UserMailer.magic_link_email(user.email, token).deliver

        success(token: token)
      else
        failure("User not found")
      end
    end

    private

    def generate_token(user)
      # Purpose ensures this token is only valid for Magic Login
      user.signed_id(expires_in: 15.minutes, purpose: :magic_link)
    end
  end
end
