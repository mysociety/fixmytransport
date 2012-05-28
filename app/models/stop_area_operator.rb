class StopAreaOperator < ActiveRecord::Base
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generation
  exists_in_data_generation(:identity_fields => [:stop_area_id, :operator_id])
  belongs_to :operator
  belongs_to :stop_area
  # virtual attribute used for adding new stop area operators
  attr_accessor :_add
  has_paper_trail :meta => { :replayable  => Proc.new { |instance| instance.replayable },
                             :replay_of => Proc.new { |instance| instance.replay_of } }

end
