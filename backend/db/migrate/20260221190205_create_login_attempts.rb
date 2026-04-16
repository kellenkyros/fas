class CreateLoginAttempts < ActiveRecord::Migration[8.1]
  def change
    create_table :login_attempts do |t|
      # If your users table is named 'users', this is correct:
      t.references :user, null: false, foreign_key: true
      
      t.string :external_id, null: false
      t.string :magic_token, null: false
      t.string :access_token
      t.string :status, default: 'pending', null: false
      t.datetime :authorized_at

      t.timestamps
    end

    add_index :login_attempts, :external_id, unique: true
    add_index :login_attempts, :magic_token, unique: true
  end
end
