class RemoveConfirmedFlagFromCampaigns < ActiveRecord::Migration
  def self.up
    remove_column :campaigns, :confirmed
  end

  def self.down
    add_column :campaigns, :confirmed, :boolean
  end
end
