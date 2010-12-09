class RenameCampaignCommentsToComments < ActiveRecord::Migration
  def self.up
    rename_table :campaign_comments, :comments
  end

  def self.down
    rename_table :comments, :campaign_comments
  end
end
