class AddCodeAndGensIndexStopAreas < ActiveRecord::Migration
  def self.up
     add_index :stop_areas, [:code, :generation_low, :generation_high],
               :name => 'index_stop_areas_on_code_and_gens'
  end

  def self.down
     remove_index :stop_areas, :name => 'index_stop_areas_on_code_and_gens'
  end
end
