class AddCategoryToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :category, :string
  end

  def self.down
    remove_column :campaigns, :category
  end
end
