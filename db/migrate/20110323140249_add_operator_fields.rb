class AddOperatorFields < ActiveRecord::Migration
  def self.up
    add_column :operators, :company_no, :string
    add_column :operators, :registered_address, :text
    add_column :operators, :url, :text
  end

  def self.down
    remove_column :operators, :company_no
    remove_column :operators, :registered_address
    remove_column :operators, :url
  end
end
