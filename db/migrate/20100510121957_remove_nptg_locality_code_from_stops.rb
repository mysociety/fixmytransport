class RemoveNptgLocalityCodeFromStops < ActiveRecord::Migration
  def self.up
    remove_column :stops, :nptg_locality_code
  end

  def self.down
    add_column :stops, :nptg_locality_code, :string
  end
end
