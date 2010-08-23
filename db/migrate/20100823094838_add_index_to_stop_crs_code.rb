class AddIndexToStopCrsCode < ActiveRecord::Migration
  def self.up
    add_index :stops, :crs_code
  end

  def self.down
    remove_index :stops, :crs_code
  end
end
