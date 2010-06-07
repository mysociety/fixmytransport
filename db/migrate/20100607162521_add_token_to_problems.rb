class AddTokenToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :token, :text
  end

  def self.down
    remove_column :problems, :token
  end
end
