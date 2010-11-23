class CreateOutgoingMessages < ActiveRecord::Migration
  def self.up
    create_table :outgoing_messages do |t|
      t.integer :campaign_id
      t.integer :status_code
      t.integer :author_id
      t.text :body
      t.datetime :sent_at
      t.timestamps
    end
  end

  def self.down
    drop_table :outgoing_messages
  end
end
