class AddFromToIncomingMessage < ActiveRecord::Migration
  def self.up
    add_column :incoming_messages, :from, :string
  end

  def self.down
    remove_column :incoming_messages, :from
  end
end
