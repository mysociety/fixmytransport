# == Schema Information
# Schema version: 20100419121920
#
# Table name: stop_types
#
#  id                :integer         not null, primary key
#  code              :string(255)
#  description       :string(255)
#  on_street         :boolean
#  point_type        :string(255)
#  version           :float
#  created_at        :datetime
#  updated_at        :datetime
#  transport_mode_id :integer
#

class StopType < ActiveRecord::Base
  has_many :transport_mode_stop_types
  has_many :transport_modes, :through => :transport_mode_stop_types
  
  def self.codes_for_transport_mode(transport_mode_id)
    stop_types = find_all_by_transport_mode_id(transport_mode_id)
    stop_types.map{ |stop_type| stop_type.code }
  end
  
end
