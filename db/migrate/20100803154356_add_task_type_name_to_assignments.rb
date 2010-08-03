class AddTaskTypeNameToAssignments < ActiveRecord::Migration
  def self.up
    add_column :assignments, :task_type_name, :string
  end

  def self.down
    remove_column :assignments, :task_type_name
  end
end
