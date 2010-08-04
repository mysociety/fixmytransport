class CreateStopOperators < ActiveRecord::Migration
  def self.up
    create_table :stop_operators do |t|
      t.integer :operator_id
      t.integer :stop_id

      t.timestamps
    end
    add_foreign_key :stop_operators, :operators, { :dependent => :nullify } 
    add_foreign_key :stop_operators, :stops, { :dependent => :nullify }
  end

  def self.down
    drop_table :stop_operators
  end
end
