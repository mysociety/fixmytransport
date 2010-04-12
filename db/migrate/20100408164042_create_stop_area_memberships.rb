class CreateStopAreaMemberships < ActiveRecord::Migration
  def self.up
    create_table :stop_area_memberships do |t|
      t.integer :stop_id
      t.integer :stop_area_id
      t.datetime :creation_datetime
      t.datetime :modification_datetime
      t.integer :revision_number
      t.string :modification

      t.timestamps
    end
    add_foreign_key :stop_area_memberships, :stop_areas, { :dependent => :destroy } 
    add_foreign_key :stop_area_memberships, :stops, { :dependent => :destroy }     
  end

  def self.down
    drop_table :stop_area_memberships
  end
end
