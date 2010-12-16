class CreateOperatorContacts < ActiveRecord::Migration
  def self.up
    create_table :operator_contacts do |t|
      t.integer :operator_id
      t.integer :location_id
      t.string :location_type
      t.string :category
      t.string :email
      t.boolean :confirmed
      t.string :notes

      t.timestamps
    end
  end

  def self.down
    drop_table :operator_contacts
  end
end
