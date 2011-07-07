class AddIndexesOnCampaigns < ActiveRecord::Migration
  def self.up
    remove_column :campaigns, :subdomain
    add_index :campaigns, :initiator_id
    add_index :campaigns, [:location_id, :location_type],  :name => 'index_campaigns_on_location_id_and_location_type'
  end

  def self.down
    add_column :campaigns, :subdomain, :string
    remove_index :campaigns, :initiator_id
    remove_index :campaigns, 'location_id_and_location_type'
  end
end
