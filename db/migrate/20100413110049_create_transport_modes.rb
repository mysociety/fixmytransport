class CreateTransportModes < ActiveRecord::Migration
  def self.up
    create_table :transport_modes do |t|
      t.string :name

      t.timestamps
    end
  end

  def self.down
    drop_table :transport_modes
  end
end
