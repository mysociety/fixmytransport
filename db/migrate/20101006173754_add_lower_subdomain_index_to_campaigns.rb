class AddLowerSubdomainIndexToCampaigns < ActiveRecord::Migration
  def self.up
    remove_index :campaigns, :subdomain
    execute "CREATE INDEX index_campaigns_on_subdomain_lower ON campaigns ((lower(subdomain)));"
  end 

  def self.down
    remove_index :campaigns, 'subdomain_lower'
  end

end
