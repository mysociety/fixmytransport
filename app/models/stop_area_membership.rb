# == Schema Information
# Schema version: 20100707152350
#
# Table name: stop_area_memberships
#
#  id                    :integer         not null, primary key
#  stop_id               :integer
#  stop_area_id          :integer
#  creation_datetime     :datetime
#  modification_datetime :datetime
#  revision_number       :integer
#  modification          :string(255)
#  created_at            :datetime
#  updated_at            :datetime
#

class StopAreaMembership < ActiveRecord::Base
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generations
  exists_in_data_generation( :identity_fields => [{:stop => [:persistent_id]},
                                                  {:stop_area => [:persistent_id]}],
                             :descriptor_fields => [],
                             :deletion_field => :modification,
                             :deletion_value => 'del',
                             :data_generation_associations => [:stop, :stop_area] )
  belongs_to :stop_area
  belongs_to :stop
  has_paper_trail :meta => { :replayable  => Proc.new { |instance| instance.replayable },
                             :replay_of => Proc.new { |instance| instance.replay_of },
                             :generation => CURRENT_GENERATION }

  diff :include => [:stop_id, :stop_area_id]
end
