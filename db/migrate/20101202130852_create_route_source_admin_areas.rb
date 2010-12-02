class CreateRouteSourceAdminAreas < ActiveRecord::Migration
  def self.up
    create_table :route_source_admin_areas do |t|
      t.integer :route_id
      t.integer :source_admin_area_id
      t.timestamps
    end
    
    add_index :route_source_admin_areas, :route_id
    add_index :route_source_admin_areas, :source_admin_area_id
  end

  def self.down
    drop_table :route_source_admin_areas
  end
  
  
end
