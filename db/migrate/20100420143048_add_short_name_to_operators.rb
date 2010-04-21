class AddShortNameToOperators < ActiveRecord::Migration
  def self.up
    add_column :operators, :short_name, :string
  end

  def self.down
    remove_column :operators, :short_name
  end
end
