class CreateActionConfirmations < ActiveRecord::Migration
  def self.up
    create_table :action_confirmations do |t|
      t.string :token, :default => '', :null => false
      t.integer :user_id, :null => false
      t.integer :target_id
      t.string :target_type
      t.timestamps
    end
    add_index :action_confirmations, :token
  end

  def self.down
    drop_table :action_confirmations
  end
end
