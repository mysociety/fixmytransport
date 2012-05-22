class AddGenerationColumnsToStopAreaLinks < ActiveRecord::Migration
  def self.up
    add_column :stop_area_links, :generation_low, :integer
    add_column :stop_area_links, :generation_high, :integer
    add_column :stop_area_links, :previous_id, :integer
    add_column :stop_area_links, :persistent_id, :integer
    remove_index :stop_area_links, :ancestor_id
    remove_index :stop_area_links, :descendant_id
    add_index :stop_area_links, [:ancestor_id, :generation_low, :generation_high]
    add_index :stop_area_links, [:descendant_id, :generation_low, :generation_high]
  end

  def self.down
    remove_column :stop_area_links, :generation_low
    remove_column :stop_area_links, :generation_high
    remove_column :stop_area_links, :previous_id
    remove_column :stop_area_links, :persistent_id
    add_index :stop_area_links, :ancestor_id
    add_index :stop_area_links, :descendant_id
  end
end
