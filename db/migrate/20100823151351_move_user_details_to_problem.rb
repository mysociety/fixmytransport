class MoveUserDetailsToProblem < ActiveRecord::Migration
  def self.up
    add_column :problems, :reporter_name, :string
    add_column :problems, :reporter_public, :boolean
    add_column :problems, :reporter_phone, :string
    add_column :updates, :reporter_name, :string
    remove_column :users, :public
  end

  def self.down
    remove_column :problems, :reporter_phone
    remove_column :problems, :reporter_public
    remove_column :problems, :reporter_name
    remove_column :updates, :reporter_name
    add_column :users, :public, :boolean
  end
end
