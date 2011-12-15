class CreateAdminUser < ActiveRecord::Migration
  def self.up
    create_table :admin_users do |t|
      t.integer :user_id, :null => false
      t.string :crypted_password
      t.string :password_salt
      t.string :persistence_token
      t.integer :login_count, :null => false, :default => 0
      t.integer :failed_login_count, :null => false, :default => 0
      t.datetime :last_request_at
      t.datetime :current_login_at
      t.datetime :last_login_at
      t.timestamps
    end
  end

  def self.down
    drop_table :admin_users
  end
end
