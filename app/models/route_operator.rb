# == Schema Information
# Schema version: 20100506162135
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
  belongs_to :operator
  belongs_to :route
  has_paper_trail
  attr_accessor :_add
end
