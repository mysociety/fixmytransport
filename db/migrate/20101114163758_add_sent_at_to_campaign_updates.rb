class AddSentAtToCampaignUpdates < ActiveRecord::Migration
  def self.up
    add_column :campaign_updates, :sent_at, :datetime
  end

  def self.down
    remove_column :campaign_updates, :sent_at
  end
end
