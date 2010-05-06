class CreateLocalityLinks < ActiveRecord::Migration
  def self.up
    create_table :locality_links do |t|
      t.integer :ancestor_id
      t.integer :descendant_id
      t.boolean :direct
      t.integer :count

      t.timestamps
    end
  end

  def self.down
    drop_table :locality_links
  end
end
