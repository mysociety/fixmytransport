class AddIsAdviceRequestToCampaignUpdates < ActiveRecord::Migration
  def self.up
    add_column :campaign_updates, :is_advice_request, :boolean
  end

  def self.down
    remove_column :campaign_updates, :is_advice_request
  end
end
