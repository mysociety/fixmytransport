class AddDefaultJourneyIdToRoutes < ActiveRecord::Migration
  def self.up
    add_column :routes, :default_journey_id, :integer
  end

  def self.down
    remove_column :routes, :default_journey_id
  end
end
