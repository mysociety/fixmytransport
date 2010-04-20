class CreateRouteOperators < ActiveRecord::Migration
  def self.up
    create_table :route_operators do |t|
      t.integer :operator_id
      t.integer :route_id

      t.timestamps
    end
    add_foreign_key :route_operators, :operators, { :dependent => :nullify } 
    add_foreign_key :route_operators, :routes, { :dependent => :nullify } 
  end

  def self.down
    drop_table :route_operators
  end
end
