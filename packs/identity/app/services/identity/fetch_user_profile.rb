module Identity
  class FetchUserProfile < ::Core::BaseService
    attr_reader :user_id

    def initialize(user_id)
      @user_id = user_id
    end

    def call
      # Accessing the private User model is allowed here because we are inside the core pack.
      user = User.find_by(id: user_id)

      if user
        # We call the class-level helper method defined below.
        success(profile_hash(user))
        # ServiceResult.new(success?: true, data: profile_hash(user), errors: [])
      else
        failure("User not found")
        # ServiceResult.new(success?: false, data: nil, errors: [ 'User not found' ])
      end
    end

    private

    def profile_hash(user)
      {
        email: user.email,
        joined_at: user.created_at.iso8601
      }
    end
  end
end
