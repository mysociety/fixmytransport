class AddFromAndToToLocationSearches < ActiveRecord::Migration
  def self.up
    add_column :location_searches, :from, :string
    add_column :location_searches, :to, :string
  end

  def self.down
    remove_column :location_searches, :to
    remove_column :location_searches, :from
  end
end
