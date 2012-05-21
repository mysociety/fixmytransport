class StopAreaOperator < ActiveRecord::Base
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generation
  exists_in_data_generation(:identity_fields => [:stop_area_id, :operator_id],
                            :new_record_fields => [],
                            :update_fields => [])
  belongs_to :operator
  belongs_to :stop_area
  # virtual attribute used for adding new stop area operators
  attr_accessor :_add
  has_paper_trail :meta => { :replayable  => Proc.new { |stop_area_operator| stop_area_operator.replayable } }

end
