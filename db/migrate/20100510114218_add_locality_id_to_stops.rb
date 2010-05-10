class AddLocalityIdToStops < ActiveRecord::Migration
  def self.up
    add_column :stops, :locality_id, :integer
  end

  def self.down
    remove_column :stops, :locality_id
  end
end
