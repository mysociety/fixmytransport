class AddGenerationToStops < ActiveRecord::Migration
  def self.up
    add_column :stops, :generation_high, :integer
    add_column :stops, :generation_low, :integer
  end

  def self.down
    remove_column :stops, :generation
  end
end
