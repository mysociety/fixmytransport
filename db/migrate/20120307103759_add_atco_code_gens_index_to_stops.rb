class AddAtcoCodeGensIndexToStops < ActiveRecord::Migration
  def self.up
    add_index :stops, [:atco_code, :generation_low, :generation_high],
              :name => 'index_stops_on_atco_code_and_gens'
  end

  def self.down
    remove_index :stops, :name => 'index_stops_on_atco_code_and_gens'
  end
end
