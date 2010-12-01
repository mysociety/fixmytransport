class RemoveReporterPublicFromProblem < ActiveRecord::Migration
  def self.up
    remove_column :problems, :reporter_public
  end

  def self.down
    add_column :problems, :reporter_public, :boolean
  end
end
