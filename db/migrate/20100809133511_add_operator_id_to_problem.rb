class AddOperatorIdToProblem < ActiveRecord::Migration
  def self.up
    add_column :problems, :operator_id, :integer
  end

  def self.down
    remove_column :problems, :operator_id
  end
end
