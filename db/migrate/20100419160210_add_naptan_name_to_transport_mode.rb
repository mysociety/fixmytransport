class AddNaptanNameToTransportMode < ActiveRecord::Migration
  def self.up
    add_column :transport_modes, :naptan_name, :string
  end

  def self.down
    remove_column :transport_modes, :naptan_name
  end
end
