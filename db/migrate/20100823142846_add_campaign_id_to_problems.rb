class AddCampaignIdToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :campaign_id, :integer
  end

  def self.down
    remove_column :problems, :campaign_id
  end
end
