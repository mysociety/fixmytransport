class CreateMergeLog < ActiveRecord::Migration
  def self.up
    create_table :merge_logs do |t|
      t.string :model_name
      t.integer :from_id
      t.integer :to_id
      t.timestamps
    end
  end

  def self.down
    drop_table :merge_logs
  end
end
