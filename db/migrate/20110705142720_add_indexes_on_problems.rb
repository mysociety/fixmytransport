class AddIndexesOnProblems < ActiveRecord::Migration
  def self.up
    add_index :problems, :campaign_id
    add_index :problems, :reporter_id
    add_index :problems, [:location_id, :location_type],  :name => 'index_problems_on_location_id_and_location_type'
  end

  def self.down
    remove_index :problems, :campaign_id
    remove_index :problems, :reporter_id
    remove_index :problems, 'location_id_and_location_type'
  end
end
