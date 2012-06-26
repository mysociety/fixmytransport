class StopOperator < ActiveRecord::Base
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generation
  exists_in_data_generation(:identity_fields => [{ :stop => [ :persistent_id ] },
                                                 { :operator => [ :persistent_id ] }],
                            :descriptor_fields => [],
                            :data_generation_associations => [:stop, :operator])
  belongs_to :operator
  belongs_to :stop
  validate :stop_operator_unique_in_generation
  has_paper_trail :meta => { :replayable  => Proc.new { |instance| instance.replayable },
                             :replay_of => Proc.new { |instance| instance.replay_of },
                             :generation => CURRENT_GENERATION }
  diff :include => [:stop_id, :operator_id]

  def stop_operator_unique_in_generation
    self.field_unique_in_generation(:operator_id, :scope => [:stop_id])
  end

end
