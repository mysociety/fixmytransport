class CreateResponsibilities < ActiveRecord::Migration
  def self.up
    create_table :responsibilities do |t|
      t.integer :problem_id
      t.string :organization_type
      t.integer :organization_id
      t.timestamps
    end
  end

  def self.down
    drop_table :responsibilities
  end
end
