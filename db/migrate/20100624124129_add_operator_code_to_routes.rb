class AddOperatorCodeToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :operator_code, :string
    add_index :routes, :operator_code
  end

  def self.down
    remove_column :routes, :operator_code
  end
end
