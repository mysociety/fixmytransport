class CreateStopTypes < ActiveRecord::Migration
  def self.up
    create_table :stop_types do |t|
      t.string :code
      t.string :description
      t.boolean :on_street
      t.string :mode
      t.string :point_type
      t.float :version

      t.timestamps
    end
  end

  def self.down
    drop_table :stop_types
  end
end
