class CreateCampaignSupporters < ActiveRecord::Migration
  def self.up
    create_table :campaign_supporters do |t|
      t.integer :campaign_id 
      t.integer :supporter_id
      t.datetime :confirmed_at
      t.text :token
      t.timestamps
    end
  end

  def self.down
    drop_table :campaign_supporters
  end
end
