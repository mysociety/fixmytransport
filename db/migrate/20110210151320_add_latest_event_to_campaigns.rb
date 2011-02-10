class AddLatestEventToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :latest_event_at, :datetime
  end

  def self.down
    remove_column :campaigns, :latest_event_at
  end
end
