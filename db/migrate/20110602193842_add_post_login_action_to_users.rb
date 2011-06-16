class AddPostLoginActionToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :post_login_action, :string
  end

  def self.down
    remove_column :users, :post_login_action
  end
end
