class AddSubTypeToStopTypes < ActiveRecord::Migration
  def self.up
    add_column :stop_types, :sub_type, :string
  end

  def self.down
    remove_column :stop_types, :sub_type
  end
end
