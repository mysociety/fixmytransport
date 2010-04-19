class AddStopAreaIdToProblem < ActiveRecord::Migration
  def self.up
    add_column :problems, :stop_area_id, :integer
    add_foreign_key :problems, :stops, { :column => :stop_id, :dependent => :nullify, :name => 'problems_stop_id_fk' } 
    add_foreign_key :problems, :stop_areas, { :column => :stop_area_id, :dependent => :nullify, :name => 'problems_stop_area_id_fk' }     
  end

  def self.down
    remove_foreign_key :problems, { :column => :stop_id }
    remove_foreign_key :problems, { :column => :stop_area_id }
    remove_column :problems, :stop_area_id
  end
end
