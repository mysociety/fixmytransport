class RemoveLocalityNamesFromStops < ActiveRecord::Migration
  def self.up
    remove_column :stops, :locality_name
    remove_column :stops, :parent_locality_name
    remove_column :stops, :grand_parent_locality_name
  end

  def self.down
    add_column :stops, :grand_parent_locality_name, :string
    add_column :stops, :locality_name, :string
    add_column :stops, :parent_locality_name, :string
  end
end
