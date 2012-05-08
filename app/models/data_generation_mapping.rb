class DataGenerationMapping < ActiveRecord::Base
  belongs_to :old_data_generation, :class_name => 'DataGeneration'
  belongs_to :new_data_generation, :class_name => 'DataGeneration'
  serialize :old_model_hash
  serialize :new_model_hash
end