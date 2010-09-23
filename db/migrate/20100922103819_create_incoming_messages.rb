class CreateIncomingMessages < ActiveRecord::Migration
  def self.up
    create_table :incoming_messages do |t|
      t.text :subject
      t.integer :campaign_id
      t.timestamps
    end
  end

  def self.down
    drop_table :incoming_messages
  end
end
