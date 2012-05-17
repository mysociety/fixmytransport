class StopOperator < ActiveRecord::Base
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generation
  exists_in_data_generation()
  belongs_to :operator, :conditions => Operator.data_generation_conditions
  belongs_to :stop, :conditions => Stop.data_generation_conditions
  has_paper_trail
end
