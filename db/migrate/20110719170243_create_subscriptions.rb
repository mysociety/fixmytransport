class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.integer :target_id
      t.string :target_type 
      t.integer :user_id
      t.text :token
      t.timestamps
    end
    add_index :subscriptions, [:target_id, :target_type],  :name => 'index_subscriptions_on_target_id_and_target_type'
    add_index :subscriptions, :user_id
  end

  def self.down
    drop_table :subscriptions
  end
end
