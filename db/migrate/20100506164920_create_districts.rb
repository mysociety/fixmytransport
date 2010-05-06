class CreateDistricts < ActiveRecord::Migration
  def self.up
    create_table :districts do |t|
      t.string :code
      t.text :name
      t.integer :admin_area_id
      t.datetime :creation_datetime
      t.datetime :modification_datetime
      t.string :revision_number
      t.string :modification

      t.timestamps
    end
  end

  def self.down
    drop_table :districts
  end
end
