class StopOperator < ActiveRecord::Base
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generation
  exists_in_data_generation()
  belongs_to :operator
  belongs_to :stop
  has_paper_trail :meta => { :replayable  => Proc.new { |stop_operator| stop_operator.replayable },
                             :persistent_id => Proc.new { |stop_operator| stop_operator.persistent_id } }
end
