class AddConfirmedAtToCampaignComment < ActiveRecord::Migration
  def self.up
    add_column :campaign_comments, :token, :string
  end

  def self.down
    remove_column :campaign_comments, :token
  end
end
