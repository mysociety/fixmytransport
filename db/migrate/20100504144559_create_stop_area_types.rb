class CreateStopAreaTypes < ActiveRecord::Migration
  def self.up
    create_table :stop_area_types do |t|
      t.string :code
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :stop_area_types
  end
end
