class RemoveOperatorAndPteFromProblems < ActiveRecord::Migration
  def self.up
    remove_column :problems, :operator_id
    remove_column :problems, :passenger_transport_executive_id
    remove_column :problems, :council_info
  end

  def self.down
    add_column :problems, :operator_id, :integer
    add_column :problems, :passenger_transport_executive_id, :integer
    add_column :problems, :council_info, :string
  end
end
