class AddEmailLocalPartToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :email_local_part, :string
  end

  def self.down
    remove_column :users, :email_local_part
  end
end
