class ReAddMetaphonesToStopAreas < ActiveRecord::Migration
  def self.up
    remove_column :stop_areas, :double_metaphone
    add_column :stop_areas, :primary_metaphone, :string
    add_column :stop_areas, :secondary_metaphone, :string
    add_index :stop_areas, :primary_metaphone
    add_index :stop_areas, :secondary_metaphone
  end

  def self.down
    add_column :stop_areas, :double_metaphone, :string
    add_index :stop_areas, :double_metaphone
    remove_column :stop_areas, :primary_metaphone
    remove_column :stop_areas, :secondary_metaphone
    remove_index :stop_areas, :primary_metaphone
    remove_index :stop_areas, :secondary_metaphone
  end
end
