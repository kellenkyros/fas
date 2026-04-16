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

      result = Identity::GenerateUserSession.call(user: user, metadata: @metadata)
      if result.success?
        success(result.data)
      else
        failure("Session generation failed")
      end
    rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
      # The find_signed! method raises an error if the token is bad or expired
      failure('Invalid or Expired Link')
    end
  end
end

