class CreateCampaignUpdates < ActiveRecord::Migration
  def self.up
   create_table :campaign_updates do |t|
      t.integer :campaign_id
      t.integer :incoming_message_id
      t.integer :user_id
      t.text :text
      t.timestamps
    end
  end

  def self.down
    drop_table :campaign_updates
  end
end
