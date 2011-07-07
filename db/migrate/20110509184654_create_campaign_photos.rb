class CreateCampaignPhotos < ActiveRecord::Migration
  def self.up
    create_table :campaign_photos do |t|
      t.integer :campaign_id
      t.timestamps
    end
    add_index :campaign_photos, :campaign_id
  end

  def self.down
    drop_table :campaign_photos
  end
end
