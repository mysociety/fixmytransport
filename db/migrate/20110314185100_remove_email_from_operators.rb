class RemoveEmailFromOperators < ActiveRecord::Migration
  def self.up
    remove_column :operators, :email
    remove_column :operators, :email_confirmed
  end

  def self.down
    add_column :operators, :email, :text
    add_column :operators, :email_confirmed, :boolean
  end
end
