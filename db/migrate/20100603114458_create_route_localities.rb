class CreateRouteLocalities < ActiveRecord::Migration
  def self.up
    create_table :route_localities do |t|
      t.integer :locality_id
      t.integer :route_id

      t.timestamps
    end
  end

  def self.down
    drop_table :route_localities
  end
end
