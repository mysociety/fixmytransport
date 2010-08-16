class CreateUpdates < ActiveRecord::Migration
  def self.up
    create_table :updates do |t|
      t.integer :problem_id
      t.text :title
      t.integer :reporter_id
      t.text :text
      t.boolean :status_code
      t.datetime :confirmed_at

      t.timestamps
    end
  end

  def self.down
    drop_table :updates
  end
end
