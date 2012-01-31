class CreateDataGenerations < ActiveRecord::Migration
  def self.up
    create_table :data_generations do |t|
      t.string :name
      t.text :description
      t.timestamps
    end
  end

  def self.down
    drop_table :data_generations
  end
end
