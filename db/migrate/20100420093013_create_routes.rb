class CreateRoutes < ActiveRecord::Migration
  def self.up
    create_table :routes do |t|
      t.integer :transport_mode_id
      t.string :number

      t.timestamps
    end
    add_foreign_key :routes, :transport_modes, { :dependent => :nullify } 
  end

  def self.down
    drop_table :routes
  end
end
