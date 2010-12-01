class AddConfirmedAtToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :confirmed_at, :datetime
  end

  def self.down
    remove_column :campaigns, :confirmed_at
  end
end
