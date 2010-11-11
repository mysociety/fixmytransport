class AddLowerSubdomainIndexToCampaigns < ActiveRecord::Migration
  def self.up
    execute "CREATE INDEX index_campaigns_on_subdomain_lower ON campaigns ((lower(subdomain)));"
  end 

  def self.down
    remove_index :campaigns, 'subdomain_lower'
  end

end
