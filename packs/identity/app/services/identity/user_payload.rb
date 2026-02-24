module Identity
  UserPayload = Struct.new(:id, :email, :created_at, keyword_init: true) do
    def self.from_user(user)
      new(
        id: user.id,
        email: user.email,
        created_at: user.created_at
      )
    end
  end
end
