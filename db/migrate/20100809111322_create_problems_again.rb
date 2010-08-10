class CreateProblemsAgain < ActiveRecord::Migration
  def self.up
     create_table :problems do |t|
        t.text :subject
        t.text :description
        t.integer :location_id
        t.string :location_type
        t.integer :transport_mode_id
        t.string :token
        t.integer :reporter_id
        t.string :category
        t.timestamps
      end
  end

  def self.down
    drop_table :problems
  end
end
