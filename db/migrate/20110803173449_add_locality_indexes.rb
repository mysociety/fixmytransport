class AddLocalityIndexes < ActiveRecord::Migration
  def self.up
    add_index :localities, :district_id
    add_index :localities, :admin_area_id
  end

  def self.down
    remove_index :localities, :district_id
    remove_index :localities, :admin_area_id
  end
end
