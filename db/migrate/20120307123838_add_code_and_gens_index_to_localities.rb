class AddCodeAndGensIndexToLocalities < ActiveRecord::Migration
  def self.up
    add_index :localities, [:code, :generation_low, :generation_high],
              :name => 'index_localities_on_code_and_gens'
  end

  def self.down
    remove_index :localities, :name => 'index_localities_on_code_and_gens'
  end
end
