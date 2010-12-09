class AddTransportModeIdToOperators < ActiveRecord::Migration
  def self.up
    add_column :operators, :transport_mode_id, :integer
  end

  def self.down
    remove_column :operators, :transport_mode_id
  end
end
