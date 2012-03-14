class RemoveAlternativeNames < ActiveRecord::Migration
  def self.up
    drop_table :alternative_names
  end

  def self.down
    create_table :alternative_names do |t|
      t.integer :alternative_locality_id
      t.integer :locality_id
      t.datetime :creation_datetime
      t.datetime :modification_datetime
      t.string :revision_number
      t.string :modification

      t.timestamps
    end
  end
end
