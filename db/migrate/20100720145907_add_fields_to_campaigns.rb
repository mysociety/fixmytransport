class AddFieldsToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :token, :text
    add_column :campaigns, :reporter_id, :integer
  end

  def self.down
    remove_column :campaigns, :reporter_id
    remove_column :campaigns, :token
  end
end
