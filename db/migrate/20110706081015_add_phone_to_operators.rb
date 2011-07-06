class AddPhoneToOperators < ActiveRecord::Migration
  def self.up
    add_column :operators, :phone, :string
  end

  def self.down
    remove_column :operators, :phone
  end
end
