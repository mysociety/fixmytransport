class AddAssignmentToOutgoingMessages < ActiveRecord::Migration
  def self.up
    add_column :outgoing_messages, :assignment_id, :integer
  end

  def self.down
    remove_column :outgoing_messages, :assignment_id
  end
end
