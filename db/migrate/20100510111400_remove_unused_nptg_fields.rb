class RemoveUnusedNptgFields < ActiveRecord::Migration
  def self.up
    remove_column :localities, :region_code
    remove_column :localities, :atco_code
    remove_column :localities, :country
    remove_column :localities, :contact_email
    remove_column :localities, :contact_telephone
    remove_column :localities, :qualifier_locality
    remove_column :localities, :qualifier_district
    remove_column :admin_areas, :contact_telephone
    remove_column :admin_areas, :contact_email
  end

  def self.down
    add_column :admin_areas, :contact_email, :string
    add_column :admin_areas, :contact_telephone, :string
    add_column :localities, :qualifier_district, :text
    add_column :localities, :qualifier_locality, :text
    add_column :localities, :contact_telephone, :string
    add_column :localities, :contact_email, :string
    add_column :localities, :country, :string
    add_column :localities, :atco_code, :string
    add_column :localities, :region_code, :string
  end
end
