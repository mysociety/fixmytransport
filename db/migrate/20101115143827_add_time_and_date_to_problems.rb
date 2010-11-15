class AddTimeAndDateToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :time, :time
    add_column :problems, :date, :date
  end

  def self.down
    remove_column :problems, :date
    remove_column :problems, :time
  end
end
