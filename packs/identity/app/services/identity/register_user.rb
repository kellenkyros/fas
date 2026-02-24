module Identity
  class RegisterUser < ::Core::BaseService
    attr_reader :params

    def initialize(params)
      @params = params
    end

    protected

    def call
      result = nil

      ::ActiveRecord::Base.transaction do
        # 1. Create User
        user = ::Identity::User.new(email: params[:email])
        unless user.save
          # The 'rollback' happens because we return and the block finishes
          # but we need to ensure the transaction actually rolls back.
          # We use 'raise ActiveRecord::Rollback' to be safe.
          raise ActiveRecord::Rollback and return failure(user.errors.full_messages)
        end

        # 2. Create Credential
        credential = user.credentials.build(
          cred_type: :password,
          password: params[:password],
          password_confirmation: params[:password_confirmation]
        )

        unless credential.save
          raise ActiveRecord::Rollback and return failure(credential.errors.full_messages)
        end

        # 3. Success!
        result = success(::Identity::UserPayload.from_user(user))
      end

      # Post-transaction side effects (Only if result was successful)
      if result&.success?
        ::Identity::UserMailer.welcome_email(result.data.email).deliver_later
      end

      result || failure("Registration failed")
    end
  end
end
