class AddRoleAndGroupToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :role, :string, null: false, default: "user"
    add_reference :users, :group, foreign_key: true

    add_check_constraint :users, "role IN ('admin', 'user')", name: "users_role_check"
  end
end
