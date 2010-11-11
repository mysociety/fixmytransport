class CreateOperatorCodes < ActiveRecord::Migration
  def self.up
    create_table :operator_codes do |t|
      t.integer :region_id
      t.integer :operator_id
      t.string :code

      t.timestamps
    end
  end

  def self.down
    drop_table :operator_codes
  end
end
