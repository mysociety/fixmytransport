class AddDataGenerationColumnsToOperatorCodes < ActiveRecord::Migration
  def self.up
    add_column :operator_codes, :generation_low, :integer
    add_column :operator_codes, :generation_high, :integer
    add_column :operator_codes, :previous_id, :integer
    add_index :operator_codes, [:code, :region_id, :generation_high, :generation_low]
  end

  def self.down
    remove_column :operator_codes, :generation_low
    remove_column :operator_codes, :generation_high
    remove_column :operator_codes, :previous_id
    remove_index :operator_codes, [:code, :region_id, :generation_high, :generation_low]
  end
end
