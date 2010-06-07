class AddConfirmedToProblem < ActiveRecord::Migration
  def self.up
    add_column :problems, :confirmed, :boolean, :default => false
  end

  def self.down
    remove_column :problems, :confirmed
  end
end
