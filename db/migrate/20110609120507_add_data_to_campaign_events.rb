class AddDataToCampaignEvents < ActiveRecord::Migration
  def self.up
    add_column :campaign_events, :data, :text
  end

  def self.down
    remove_column :campaign_events, :data
  end
end
