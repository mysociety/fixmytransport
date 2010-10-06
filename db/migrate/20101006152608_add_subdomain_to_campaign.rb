class AddSubdomainToCampaign < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :subdomain, :string
  end

  def self.down
    remove_column :campaigns, :subdomain
  end
end
