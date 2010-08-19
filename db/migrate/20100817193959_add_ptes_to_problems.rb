class AddPtesToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :passenger_transport_executive_id, :integer
  end

  def self.down
    remove_column :problems, :passenger_transport_executive_id
  end
end
