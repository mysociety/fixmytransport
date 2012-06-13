class AddGenerationToVersions < ActiveRecord::Migration
  def self.up
    add_column :versions, :generation, :integer
    add_index :versions, [:item_type, :replayable, :generation]
  end

  def self.down
    remove_column :versons, :generation
  end
end
