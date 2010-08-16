class AddTokenToUpdates < ActiveRecord::Migration
  def self.up
    add_column :updates, :token, :string
  end

  def self.down
    remove_column :updates, :token
  end
end
