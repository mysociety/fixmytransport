class AddConfirmedPasswordToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :confirmed_password, :boolean
  end

  def self.down
    remove_column :users, :confirmed_password
  end
end
