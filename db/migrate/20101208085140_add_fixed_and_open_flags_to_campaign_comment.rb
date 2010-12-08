class AddFixedAndOpenFlagsToCampaignComment < ActiveRecord::Migration
  def self.up
    add_column :campaign_comments, :mark_fixed, :boolean
    add_column :campaign_comments, :mark_open, :boolean
  end

  def self.down
    remove_column :campaign_comments, :mark_open
    remove_column :campaign_comments, :mark_fixed
  end
end
