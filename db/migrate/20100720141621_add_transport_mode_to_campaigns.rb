class AddTransportModeToCampaigns < ActiveRecord::Migration
  def self.up
    add_column :campaigns, :transport_mode_id, :integer
  end

  def self.down
    remove_column :campaigns, :transport_mode_id
  end
end
