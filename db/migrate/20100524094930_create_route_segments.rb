class CreateRouteSegments < ActiveRecord::Migration
  def self.up
    create_table :route_segments do |t|
      t.integer :from_stop_id
      t.integer :to_stop_id
      t.boolean :from_terminus, :default => false
      t.boolean :to_terminus, :default => false
      t.integer :route_id

      t.timestamps
    end
  end

  def self.down
    drop_table :route_segments
  end
end
