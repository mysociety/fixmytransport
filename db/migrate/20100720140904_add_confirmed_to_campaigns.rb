class AddConfirmedToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :confirmed, :boolean
  end

  def self.down
    remove_column :campaigns, :confirmed
  end
end
