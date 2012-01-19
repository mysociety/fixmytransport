class AddReferenceIdToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :reference_id, :integer
  end

  def self.down
    remove_column :problems, :reference_id
  end
end
