module Identity
  class Session < ApplicationRecord
    belongs_to :user

    scope :active, -> { where("expires_at > ?", Time.current) }

    def self.find_by_token(raw_token)
      digest = Digest::SHA256.hexdigest(raw_token)
      find_by(token_digest: digest)
    end
  end
end
