class CreateDataGenerationMappings < ActiveRecord::Migration
  def self.up
    create_table :data_generation_mappings do |t|
      t.integer :old_generation_id
      t.integer :new_generation_id
      t.string :model_name
      t.string :old_model_hash
      t.string :new_model_hash
      t.timestamps
    end
  end

  def self.down
    drop_table :data_generation_mappings
  end
end
