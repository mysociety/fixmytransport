class AddLocationPersistentIdToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :location_persistent_id, :integer
  end

  def self.down
    remove_column :campaigns, :location_persistent_id
  end
end
