class AddStatusCodeToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :status_code, :integer
  end

  def self.down
    remove_column :campaigns, :status_code
  end
end
