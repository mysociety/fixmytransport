class AddDoubleMetaphoneToLocalities < ActiveRecord::Migration
  def self.up
    add_column :localities, :primary_metaphone, :string
    add_column :localities, :secondary_metaphone, :string  
    add_index :localities, :primary_metaphone
    add_index :localities, :secondary_metaphone    
  end

  def self.down
    remove_column :localities, :primary_metaphone
    remove_column :localities, :secondary_metaphone
  end
end
