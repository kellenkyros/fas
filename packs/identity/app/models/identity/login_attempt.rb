# packs/identity/app/models/identity/login_attempt.rb
module Identity
  class LoginAttempt < ApplicationRecord
    belongs_to :user
    
    enum :status, { pending: "pending", authorized: "authorized", expired: "expired" }, default: "pending"

    before_validation :generate_secure_tokens, on: :create

    private

    def generate_secure_tokens
      # external_id: The "Channel Name" for SSE (Desktop listens here)
      self.external_id ||= SecureRandom.uuid
      
      # magic_token: The "Secret Key" in the email (Mobile clicks this)
      self.magic_token ||= SecureRandom.hex(32)
    end
  end
end
