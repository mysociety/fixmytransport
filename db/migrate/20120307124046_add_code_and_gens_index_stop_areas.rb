class AddCodeAndGensIndexStopAreas < ActiveRecord::Migration
  def self.up
     add_index :stop_areas, [:code, :generation_low, :generation_high]
  end

  def self.down
     remove_index :stop_areas, [:code, :generation_low, :generation_high]
  end
end
