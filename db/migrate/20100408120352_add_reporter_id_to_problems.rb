class AddReporterIdToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :reporter_id, :integer
    add_foreign_key :problems, :users, { :column => :reporter_id, :dependent => :nullify, :name => 'problems_reporter_id_fk' } 
  end

  def self.down
    remove_foreign_key :problems, { :column => :reporter_id }
    remove_column :problems, :reporter_id
  end
end
