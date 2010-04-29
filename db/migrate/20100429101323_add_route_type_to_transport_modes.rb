class AddRouteTypeToTransportModes < ActiveRecord::Migration
  def self.up
    add_column :transport_modes, :route_type, :string
  end

  def self.down
    remove_column :transport_modes, :route_type
  end
end
