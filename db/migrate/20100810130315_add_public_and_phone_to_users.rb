class AddAnonymousAndPhoneToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :public, :boolean
    add_column :users, :phone, :string
  end

  def self.down
    remove_column :users, :phone
    remove_column :users, :public
  end
end
