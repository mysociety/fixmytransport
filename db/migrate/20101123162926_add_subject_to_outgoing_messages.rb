class AddSubjectToOutgoingMessages < ActiveRecord::Migration
  def self.up
    add_column :outgoing_messages, :subject, :string
  end

  def self.down
    remove_column :outgoing_messages, :subject
  end
end
