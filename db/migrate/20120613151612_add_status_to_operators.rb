class AddStatusToOperators < ActiveRecord::Migration
  def self.up
    add_column :operators, :status, :string
  end

  def self.down
    remove_column :operators, :status
  end
end
