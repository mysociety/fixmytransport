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
  exists_in_data_generation( :identity_fields => [:stop_id, :stop_area_id],
                             :new_record_fields => [],
                             :update_fields => [:creation_datetime, :modification_datetime,
                                                :modification, :revision_number],
                             :deletion_field => :modification,
                             :deletion_value => 'del' )
  belongs_to :stop_area
  belongs_to :stop
  has_paper_trail :meta => { :replayable  => Proc.new { |stop_area_membership| stop_area_membership.replayable },
                             :persistent_id => Proc.new { |stop_area_membership| stop_area_membership.persistent_id } }
end
