class AddOtherCodeIndexToStops < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX index_stops_on_other_code_lower ON stops ((lower(other_code)));"
  end

  def self.down
    remove_index :stops, "other_code_lower"
  end
end
