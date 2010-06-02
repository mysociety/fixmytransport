class AddDistrictIdToLocalities < ActiveRecord::Migration
  def self.up
    add_column :localities, :district_id, :integer
  end

  def self.down
    remove_column :localities, :district_id
  end
end
