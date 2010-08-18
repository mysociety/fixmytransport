class CreateCouncilContacts < ActiveRecord::Migration
  def self.up
    create_table :council_contacts do |t|
      t.integer :area_id
      t.string :category
      t.string :email
      t.boolean :confirmed
      t.text :note

      t.timestamps
    end
  end

  def self.down
    drop_table :council_contacts
  end
end
