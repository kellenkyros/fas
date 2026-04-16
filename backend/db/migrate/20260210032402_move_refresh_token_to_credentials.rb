class MoveRefreshTokenToCredentials < ActiveRecord::Migration[8.1]
  def change
    # Remove it from users
    remove_column :users, :refresh_token, :string if column_exists?(:users, :refresh_token)
  end
end
