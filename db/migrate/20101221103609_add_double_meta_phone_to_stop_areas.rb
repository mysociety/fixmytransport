class AddDoubleMetaPhoneToStopAreas < ActiveRecord::Migration
  def self.up
    add_column :stop_areas, :double_metaphone, :string
    add_index :stop_areas, :double_metaphone
  end

  def self.down
    remove_column :stop_areas, :double_metaphone
    remove_index :stop_areas, :double_metaphone
  end
end
