class AddNocFieldsToOperators < ActiveRecord::Migration
  def self.up
    add_column :operators, :noc_code, :string
    add_column :operators, :reference_name, :string
    add_column :operators, :vosa_license_name, :string
    add_column :operators, :parent, :string
    add_column :operators, :vehicle_mode, :string
    add_column :operators, :ultimate_parent, :string
  end

  def self.down
    remove_column :operators, :ultimate_parent
    remove_column :operators, :parent
    remove_column :operators, :vosa_license_name
    remove_column :operators, :reference_name
    remove_column :operators, :vehicle_mode
    remove_column :operators, :noc_code
  end
end
