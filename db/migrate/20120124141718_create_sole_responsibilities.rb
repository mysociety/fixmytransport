class CreateSoleResponsibilities < ActiveRecord::Migration
  def self.up
     create_table :sole_responsibilities do |t|
        t.integer :council_id, :null => false
        t.timestamps
      end
  end

  def self.down
    drop_table :sole_responsibilities
  end
end
