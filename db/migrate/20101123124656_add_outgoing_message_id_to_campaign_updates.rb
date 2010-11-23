class AddOutgoingMessageIdToCampaignUpdates < ActiveRecord::Migration
  def self.up
    add_column :campaign_updates, :outgoing_message_id, :integer
  end

  def self.down
    remove_column :campaign_updates, :outgoing_message_id
  end
end
