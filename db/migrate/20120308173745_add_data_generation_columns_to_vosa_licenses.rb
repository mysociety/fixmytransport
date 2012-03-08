class AddDataGenerationColumnsToVosaLicenses < ActiveRecord::Migration
  def self.up
    add_column :vosa_licenses, :generation_low, :integer
    add_column :vosa_licenses, :generation_high, :integer
    add_column :vosa_licenses, :previous_id, :integer
  end

  def self.down
    remove_column :vosa_licenses, :generation_low
    remove_column :vosa_licenses, :generation_high
    remove_column :vosa_licenses, :previous_id
  end
end
