class RenameCouncilsToCouncilInfo < ActiveRecord::Migration
  def self.up
    rename_column :problems, :councils, :council_info
  end

  def self.down
    rename_column :problems, :council_info, :councils
  end
end
