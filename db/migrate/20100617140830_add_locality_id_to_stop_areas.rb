class AddLocalityIdToStopAreas < ActiveRecord::Migration
  def self.up
    add_column :stop_areas, :locality_id, :integer
    add_index :stop_areas, :locality_id
  end

  def self.down
    remove_column :stop_areas, :locality_id
  end
end
