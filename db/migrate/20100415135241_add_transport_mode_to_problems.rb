class AddTransportModeToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :transport_mode_id, :integer
  end

  def self.down
    remove_column :problems, :transport_mode_id
  end
end
