class AddLoadedAtToDataGenerations < ActiveRecord::Migration
  def self.up
    add_column :data_generations, :loaded_at, :datetime
  end

  def self.down
    remove_column :data_generations, :loaded_at
  end
end
