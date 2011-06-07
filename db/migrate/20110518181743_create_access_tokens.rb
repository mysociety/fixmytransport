class CreateAccessTokens < ActiveRecord::Migration
  def self.up
    create_table :access_tokens do |t|
      t.integer :user_id
      t.string :type, :limit => 30
      t.string :key # how we identify the user, in case they logout and log back in
      t.string :token, :limit => 1024 # This has to be huge because of Yahoo's excessively large tokens
      t.boolean :active # whether or not it's associated with the account
      t.timestamps
    end
    
    add_index :access_tokens, :key, :unique
  end

  def self.down
    drop_table :access_tokens
  end
end
