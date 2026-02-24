class MoveCredentialsToNewTable < ActiveRecord::Migration[8.1]
  def change
    # 1. Create the new flexible credentials table
    create_table :credentials do |t|
      t.references :user, null: false, foreign_key: true
      t.string :cred_type, null: false # 'password', 'magic_link', 'oauth'
      t.jsonb :data, default: {}, null: false

      t.timestamps
    end

    # Add a GIN index for fast JSON searching (useful for finding tokens)
    add_index :credentials, :data, using: :gin
    # Ensure a user only has one active password, etc.
    add_index :credentials, [ :user_id, :cred_type ]

    # 2. Clean up the users table
    # Only run these if you already have these columns from has_secure_password
    remove_column :users, :password_digest, :string if column_exists?(:users, :password_digest)
  end
end
