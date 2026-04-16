class AddUniqueIndexToUsersEmail < ActiveRecord::Migration[8.1]
  def change
    # unique: true creates the constraint in Postgres
    add_index :users, :email, unique: true
  end
end
