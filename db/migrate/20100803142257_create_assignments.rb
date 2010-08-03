class CreateAssignments < ActiveRecord::Migration
  def self.up
    create_table :assignments do |t|
      t.integer :user_id
      t.integer :campaign_id
      t.integer :task_id
      t.integer :status_code, :default => 0
      t.text :data

      t.timestamps
    end
  end

  def self.down
    drop_table :assignments
  end
end
