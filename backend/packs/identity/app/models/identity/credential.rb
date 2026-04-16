module Identity
  class Credential < ApplicationRecord
    belongs_to :user
    enum :cred_type, { password: "password", passkey: "passkey", magic_link: "magic_link" }, suffix: :type

    attr_accessor :password, :password_confirmation

    store_accessor :data, :public_key, :external_id, :sign_count, :nickname, :password_digest
    
    # Ensure we don't accidentally treat a password as a passkey
    scope :passkeys, -> { where(cred_type: 'passkey') }

    # Validations only run if a password is being set
    validates :password, presence: true, confirmation: true, length: { minimum: 6 }, if: :password_required?
    validates :password_confirmation, presence: true, if: :password_required?
    validate :password_complexity, if: :password_required?
    validates :public_key, :external_id, presence: true, if: :passkey_type?

    before_save :hash_password, if: :password_required?

    private

    def password_required?
      # We only care about password logic if the cred_type is password
      # and the user actually provided a string to change it.
      password.present? && password_type?
    end

    def password_complexity
      # Regex: requires at least one number [0-9] and one special char
      unless password.match?(/(?=.*[0-9])(?=.*[!@#$%^&*])/)
        errors.add :password, "is too simple. Include at least one number and one special character."
      end
    end

    def hash_password
      # Ensure data is a hash and store the BCrypt digest
      self.data ||= {}
      self.data['password_digest'] = BCrypt::Password.create(password)
    end
  end
end
