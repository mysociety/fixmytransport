class ReAddConfirmedToProblem < ActiveRecord::Migration
  def self.up
    add_column :problems, :confirmed, :boolean
  end

  def self.down
    remove_column :problems, :confirmed
  end
end
