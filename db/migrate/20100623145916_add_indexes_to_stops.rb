class AddIndexesToStops < ActiveRecord::Migration
  def self.up
    add_index :stops, :naptan_code
    add_index :stops, :stop_type
    execute "CREATE INDEX index_stops_on_street_lower ON stops ((lower(street)));"
  end

  def self.down
    remove_index :stops, :naptan_code
    remove_index :stops, :stop_type
    remove_index :stops, 'street_lower'
  end
end
