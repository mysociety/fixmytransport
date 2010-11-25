class DropUnusedTables < ActiveRecord::Migration
  def self.up
    drop_table :route_stops
    drop_table :stop_operators
  end

  def self.down
  
    create_table :route_stops do |t|
      t.integer :route_id
      t.integer :stop_id

      t.timestamps
    end
  
    add_index :route_stops, :stop_id
    add_index :route_stops, :route_id
    add_foreign_key :route_stops, :routes, { :dependent => :destroy } 
    add_foreign_key :route_stops, :stops, { :dependent => :destroy } 
    
    create_table :stop_operators do |t|
      t.integer :operator_id
      t.integer :stop_id

      t.timestamps
    end
    
    add_foreign_key :stop_operators, :operators, { :dependent => :nullify } 
    add_foreign_key :stop_operators, :stops, { :dependent => :nullify }
  
  end
end
