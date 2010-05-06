class CreateRegions < ActiveRecord::Migration
  def self.up
    create_table :regions do |t|
      t.string :code
      t.text :name
      t.datetime :creation_datetime
      t.datetime :modification_datetime
      t.string :revision_number
      t.string :modification

      t.timestamps
    end
  end

  def self.down
    drop_table :regions
  end
end
