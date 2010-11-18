class CreateCampaignComments < ActiveRecord::Migration
  def self.up
    create_table :campaign_comments do |t|
      t.integer :user_id
      t.integer :campaign_update_id
      t.integer :campaign_id
      t.text :text

      t.timestamps
    end
  end

  def self.down
    drop_table :campaign_comments
  end
end
