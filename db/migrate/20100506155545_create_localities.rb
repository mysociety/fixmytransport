class CreateLocalities < ActiveRecord::Migration
  def self.up
    create_table :localities do |t|
      t.string :code
      t.string :atco_code
      t.text :name
      t.text :short_name
      t.string :country
      t.string :region_code
      t.boolean :national
      t.string :contact_email
      t.string :contact_telephone
      t.datetime :creation_datetime
      t.datetime :modification_datetime
      t.string :revision_number
      t.string :modification

      t.timestamps
    end
  end

  def self.down
    drop_table :localities
  end
end
