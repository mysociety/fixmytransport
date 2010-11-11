class CreateVosaLicenses < ActiveRecord::Migration
  def self.up
    create_table :vosa_licenses do |t|
      t.integer :operator_id
      t.string :number

      t.timestamps
    end
  end

  def self.down
    drop_table :vosa_licenses
  end
end
