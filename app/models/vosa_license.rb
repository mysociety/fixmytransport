class VosaLicense < ActiveRecord::Base
  belongs_to :operator, :conditions => Operator.data_generation_conditions
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generations
  exists_in_data_generation( :identity_fields => [:operator_id, :number],
                             :new_record_fields => [],
                             :update_fields => [] )

end