class AddConfirmedAtToProblems < ActiveRecord::Migration
  def self.up
    add_column :problems, :confirmed_at, :datetime
  end

  def self.down
    remove_column :problems, :confirmed_at
  end
end
