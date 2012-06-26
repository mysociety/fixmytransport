class StopAreaOperator < ActiveRecord::Base
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generation
  exists_in_data_generation(:identity_fields => [{ :stop_area => [ :persistent_id ] },
                                                  { :operator => [ :persistent_id ] } ],
                            :descriptor_fields => [],
                            :data_generation_associations => [:stop_area, :operator])
  belongs_to :operator
  belongs_to :stop_area
  validate :stop_area_operator_unique_in_generation
  # virtual attribute used for adding new stop area operators
  attr_accessor :_add
  has_paper_trail :meta => { :replayable  => Proc.new { |instance| instance.replayable },
                             :replay_of => Proc.new { |instance| instance.replay_of },
                             :generation => CURRENT_GENERATION }

  diff :include => [:stop_area_id, :operator_id]

  def stop_area_operator_unique_in_generation
    self.field_unique_in_generation(:operator_id, :scope => [:stop_area_id])
  end

end
