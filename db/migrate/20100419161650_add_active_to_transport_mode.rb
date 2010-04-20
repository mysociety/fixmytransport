class AddActiveToTransportMode < ActiveRecord::Migration
  def self.up
    add_column :transport_modes, :active, :boolean
  end

  def self.down
    remove_column :transport_modes, :active
  end
end
