class AddOtherCodeToStops < ActiveRecord::Migration
  def self.up
    add_column :stops, :other_code, :string
  end

  def self.down
    remove_column :stops, :other_code
  end
end
