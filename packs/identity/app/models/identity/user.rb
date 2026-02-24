module Identity
  class User < ApplicationRecord
  # Add these associations
  has_many :credentials, dependent: :destroy
  has_many :sessions, dependent: :destroy

  # case_sensitive: false ensures "Test@Ex.com" and "test@ex.com" are treated as the same
  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  # Keep your custom authenticate method we wrote earlier
  def authenticate(password)
    password_cred = credentials.find_by(cred_type: 'password')
    return false unless password_cred

    digest = password_cred.data['password_digest']
    return false unless digest

    BCrypt::Password.new(digest) == password && self
  end
  end
end
