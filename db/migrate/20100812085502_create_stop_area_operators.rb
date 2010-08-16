class CreateStopAreaOperators < ActiveRecord::Migration
  def self.up
    create_table :stop_area_operators do |t|
      t.integer :stop_area_id
      t.integer :operator_id

      t.timestamps
    end
  end

  def self.down
    drop_table :stop_area_operators
  end
end
