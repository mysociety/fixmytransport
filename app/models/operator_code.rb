class OperatorCode < ActiveRecord::Base
  belongs_to :region
  belongs_to :operator
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generations
  exists_in_data_generation( :identity_fields => [:code,
                                                  { :region => [ :persistent_id ] },
                                                  { :operator => [ :persistent_id ] } ],
                             :descriptor_fields => [],
                             :data_generation_associations => [:region, :operator] )

  has_paper_trail :meta => { :replayable  => Proc.new { |instance| instance.replayable },
                             :replay_of => Proc.new { |instance| instance.replay_of } }

  diff :include => [:region_id, :operator_id]
end
