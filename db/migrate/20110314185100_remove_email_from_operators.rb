class RemoveEmailFromOperators < ActiveRecord::Migration
  def self.up
    remove_column :operators, :email
  end

  def self.down
    add_column :operators, :email, :text
  end
end
