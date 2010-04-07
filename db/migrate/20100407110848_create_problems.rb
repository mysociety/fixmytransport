class CreateProblems < ActiveRecord::Migration
  def self.up
    create_table :problems do |t|
      t.text :subject
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :problems
  end
end
