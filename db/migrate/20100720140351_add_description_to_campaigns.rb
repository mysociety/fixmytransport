class AddDescriptionToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :description, :text
  end

  def self.down
    remove_column :campaigns, :description
  end
end
