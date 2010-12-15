class AddFailedToLocationSearch < ActiveRecord::Migration
  def self.up
    add_column :location_searches, :failed, :boolean
  end

  def self.down
    remove_column :location_searches, :failed
  end
end
