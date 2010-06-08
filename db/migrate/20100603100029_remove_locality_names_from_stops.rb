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
    execute "CREATE INDEX index_stops_on_locality_name_lower ON stops ((lower(locality_name)));"
    execute "CREATE INDEX index_stops_on_parent_locality_name_lower ON stops ((lower(parent_locality_name)));"
    execute "CREATE INDEX index_stops_on_grand_parent_locality_name_lower ON stops ((lower(grand_parent_locality_name)));"
  end
end
