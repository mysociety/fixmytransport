class AddIndexOnCampaignSubdomain < ActiveRecord::Migration
  def self.up
    add_index :campaigns, :subdomain
  end

  def self.down
    remove_index :campaigns, :subdomain
  end
end
