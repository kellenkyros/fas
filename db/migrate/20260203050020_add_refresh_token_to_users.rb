class AddRefreshTokenToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :refresh_token, :string
    add_index :users, :refresh_token, unique: true
  end
end
