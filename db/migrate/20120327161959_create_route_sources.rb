class CreateRouteSources < ActiveRecord::Migration
  def self.up
    create_table :route_sources do |t|
      t.string :service_code
      t.string :operator_code
      t.integer :region_id
      t.integer :line_number
      t.string :filename
      t.integer :route_id
      t.timestamps
    end
  end

  def self.down
    drop_table :route_sources
  end
end
