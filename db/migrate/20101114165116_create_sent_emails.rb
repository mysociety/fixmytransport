class CreateSentEmails < ActiveRecord::Migration
  def self.up
    create_table :sent_emails do |t|
      t.integer :campaign_id
      t.integer :campaign_update_id
      t.integer :recipient_id

      t.timestamps
    end
  end

  def self.down
    drop_table :sent_emails
  end
end
