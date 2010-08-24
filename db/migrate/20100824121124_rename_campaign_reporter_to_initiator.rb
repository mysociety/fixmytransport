class RenameCampaignReporterToInitiator < ActiveRecord::Migration
  def self.up
    rename_column :campaigns, :reporter_id, :initiator_id
  end

  def self.down
    rename_column :campaigns, :initiator_id, :reporter_id
  end
end
