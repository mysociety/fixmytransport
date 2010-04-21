# == Schema Information
# Schema version: 20100420165342
#
# Table name: stop_types
#
#  id          :integer         not null, primary key
#  code        :string(255)
#  description :string(255)
#  on_street   :boolean
#  point_type  :string(255)
#  version     :float
#  created_at  :datetime
#  updated_at  :datetime
#

class StopType < ActiveRecord::Base
  has_many :transport_mode_stop_types
  has_many :transport_modes, :through => :transport_mode_stop_types
  
  def self.codes_for_transport_mode(transport_mode_id)
    transport_mode_stop_types = TransportModeStopType.find(:all, :conditions => ['transport_mode_id = ?', transport_mode_id])
    stop_type_ids = transport_mode_stop_types.map{|tmst| tmst.stop_type_id }
    stop_types = find([stop_type_ids])
    stop_types.map{ |stop_type| stop_type.code }
  end
  
end
