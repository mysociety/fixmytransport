class UpdateAlternativeNames < ActiveRecord::Migration
  def self.up
    remove_column :alternative_names, :name
    remove_column :alternative_names, :short_name
    remove_column :alternative_names, :qualifier_name
    remove_column :alternative_names, :qualifier_locality
    remove_column :alternative_names, :qualifier_district
    add_column :alternative_names, :alternative_locality_id, :integer
  end

  def self.down
    add_column :alternative_names, :name, :text
    add_column :alternative_names, :short_name, :text
    add_column :alternative_names, :qualifier_name, :text
    add_column :alternative_names, :qualifier_locality, :text
    add_column :alternative_names, :qualifier_district, :text
    remove_column :alternative_names, :alternative_locality_id
  end
end
