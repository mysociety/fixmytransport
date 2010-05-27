class AddIndexesToRouteOperators < ActiveRecord::Migration
  def self.up
    add_index :route_operators, :route_id
    add_index :route_operators, :operator_id
  end

  def self.down
    remove_index :route_operators, :route_id
    remove_index :route_operators, :operator_id
  end
end
