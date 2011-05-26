class AddNewSupporterToCampaignSupporter < ActiveRecord::Migration
  def self.up
    add_column :campaign_supporters, :new_supporter, :boolean, :default => true
  end

  def self.down
    remove_column :campaign_supporters, :new_supporter
  end
end
