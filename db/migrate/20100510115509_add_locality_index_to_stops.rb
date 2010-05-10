class AddLocalityIndexToStops < ActiveRecord::Migration
  def self.up
    add_index :stops, :locality_id
  end

  def self.down
    remove_index :stops, :locality_id
  end
end
