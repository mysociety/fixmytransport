class RemoveUpdatesTable < ActiveRecord::Migration
  def self.up
    drop_table :updates
  end

  def self.down
    create_table :updates do |t|
      t.integer :problem_id
      t.integer :reporter_id
      t.text :text
      t.datetime :confirmed_at
      t.string :token
      t.integer :status_code
      t.string :reporter_name
      t.boolean :mark_fixed
      t.boolean :mark_open
      t.timestamps
  end
  end
end
