class AddPreviousIdToStopAreaMemberships < ActiveRecord::Migration
  def self.up
    add_column :stop_area_memberships, :previous_id, :integer
    add_index :stop_area_memberships, :previous_id
  end

  def self.down
    remove_column :stop_area_memberships, :previous_id
    remove_index :stop_area_memberships, :previous_id
  end
end
