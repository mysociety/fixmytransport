class RemoveOldFieldsFromComments < ActiveRecord::Migration
  def self.up
    remove_column :comments, :campaign_id
    remove_column :comments, :campaign_update_id
    remove_column :comments, :problem_id
  end

  def self.down
    add_column :comments, :campaign_id, :integer
    add_column :comments, :campaign_update_id, :integer
    add_column :comments, :problem_id, :integer
  end
end
