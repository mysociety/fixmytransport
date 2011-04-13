class AddDistrictsToCouncilContacts < ActiveRecord::Migration
  def self.up
    add_column :council_contacts, :district_id, :integer
  end

  def self.down
    remove_column :council_contacts, :district_id
  end
end
