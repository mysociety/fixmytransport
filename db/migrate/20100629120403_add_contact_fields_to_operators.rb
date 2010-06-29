class AddContactFieldsToOperators < ActiveRecord::Migration
  def self.up
    add_column :operators, :email, :text
    add_column :operators, :email_confirmed, :boolean
    add_column :operators, :notes, :text
  end

  def self.down
    remove_column :operators, :notes
    remove_column :operators, :email_confirmed
    remove_column :operators, :email
  end
end
