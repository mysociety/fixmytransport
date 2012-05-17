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
  exists_in_data_generation(:identity_fields => [:route_id, :operator_id])

  belongs_to :operator, :conditions => Operator.data_generation_conditions
  belongs_to :route, :conditions => Route.data_generation_conditions
  has_paper_trail :meta => { :replayable  => Proc.new { |route_operator| route_operator.replayable } }
  # virtual attribute used for adding new route operators
  attr_accessor :_add

end
