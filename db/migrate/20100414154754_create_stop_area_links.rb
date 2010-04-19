class CreateStopAreaLinks < ActiveRecord::Migration
  def self.up
    create_table :stop_area_links do |t|
      t.integer :ancestor_id
      t.integer :descendant_id
      t.boolean :direct
      t.integer :count

      t.timestamps
    end
  end

  def self.down
    drop_table :stop_area_links
  end
end
