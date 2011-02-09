class CreateCampaignEvents < ActiveRecord::Migration
  def self.up
    create_table :campaign_events do |t|
      t.string :event_type
      t.integer :campaign_id
      t.string :described_type
      t.integer :described_id
      t.boolean :visible, :default => false
      t.timestamps
    end
  end

  def self.down
    drop_table :campaign_events
  end
end
