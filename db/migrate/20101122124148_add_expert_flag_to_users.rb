class AddExpertFlagToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :is_expert, :boolean
  end

  def self.down
    remove_column :users, :is_expert
  end
end
