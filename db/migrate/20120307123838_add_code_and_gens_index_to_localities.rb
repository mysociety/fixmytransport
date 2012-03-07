class AddCodeAndGensIndexToLocalities < ActiveRecord::Migration
  def self.up
    add_index :localities, [:code, :generation_low, :generation_high]
  end

  def self.down
    remove_index :localities, [:code, :generation_low, :generation_high]
  end
end
