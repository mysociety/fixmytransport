class RemoveAlternativeNames < ActiveRecord::Migration
  def self.up
    drop_table :alternative_names
  end

  def self.down
    create_table :alternative_names do |t|
      t.text :name
      t.integer :locality_id
      t.text :short_name
      t.text :qualifier_name
      t.text :qualifier_locality
      t.text :qualifier_district
      t.datetime :creation_datetime
      t.datetime :modification_datetime
      t.string :revision_number
      t.string :modification

      t.timestamps
    end
  end
end
