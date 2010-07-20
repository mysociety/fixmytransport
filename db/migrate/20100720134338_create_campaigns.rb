class CreateCampaigns < ActiveRecord::Migration
  def self.up
    create_table :campaigns do |t|
      t.integer :location_id
      t.string :location_type
      t.text :title

      t.timestamps
    end
  end

  def self.down
    drop_table :campaigns
  end
end
