class AddCouncilsToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :councils, :string
  end

  def self.down
    remove_column :problems, :councils
  end
end
