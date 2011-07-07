class RemoveEmailLocalPartFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :email_local_part
  end

  def self.down
    add_column :users, :email_local_part, :string
  end
end
