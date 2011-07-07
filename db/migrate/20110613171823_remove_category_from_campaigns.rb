class RemoveCategoryFromCampaigns < ActiveRecord::Migration
  def self.up
    remove_column :campaigns, :category
  end

  def self.down
    add_column :campaigns, :category, :string
  end
end
