# == Schema Information
# Schema version: 20100707152350
#
# Table name: route_operators
#
#  id          :integer         not null, primary key
#  operator_id :integer
#  route_id    :integer
#  created_at  :datetime
#  updated_at  :datetime
#

class RouteOperator < ActiveRecord::Base
  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generation
  exists_in_data_generation( :identity_fields => [ { :route => [ :persistent_id ] },
                                                   { :operator => [ :persistent_id ] }],
                             :descriptor_fields => [])
  belongs_to :operator
  belongs_to :route
  has_paper_trail :meta => { :replayable  => Proc.new { |instance| instance.replayable },
                             :replay_of => Proc.new { |instance| instance.replay_of } }
  # virtual attribute used for adding new route operators
  attr_accessor :_add
  diff :include => [ :route_id, :operator_id ]
end
