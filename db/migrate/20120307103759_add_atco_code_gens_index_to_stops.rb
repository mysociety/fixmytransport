class AddAtcoCodeGensIndexToStops < ActiveRecord::Migration
  def self.up
    add_index :stops, [:atco_code, :generation_low, :generation_high]
  end

  def self.down
    remove_index :stops, [:atco_code, :generation_low, :generation_high]
  end
end
