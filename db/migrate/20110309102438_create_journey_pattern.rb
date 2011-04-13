class CreateJourneyPattern < ActiveRecord::Migration
  def self.up
    create_table :journey_patterns do |t|
      t.integer :route_id
      t.string :destination
      t.timestamps
    end
    add_column :route_segments, :journey_pattern_id, :integer
    add_column :route_segments, :segment_order, :integer
  end

  def self.down
    drop_table :journey_patterns
    remove_column :route_segments, :journey_pattern_id
    remove_column :route_segments, :segment_order
  end
end
