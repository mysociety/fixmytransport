class RemoveDepartureTimeFromSubRoutes < ActiveRecord::Migration
  def self.up
    remove_column :sub_routes, :departure_time
  end

  def self.down
    add_column :sub_routes, :departure_time, :string
  end
end
