class StopAreaType < ActiveRecord::Base
  has_many :transport_mode_stop_area_types
  has_many :transport_modes, :through => :transport_mode_stop_area_types
  
  def self.codes_for_transport_mode(transport_mode_id)
    transport_mode_stop_area_types = TransportModeStopAreaType.find(:all, :conditions => ['transport_mode_id = ?', transport_mode_id])
    stop_area_type_ids = transport_mode_stop_area_types.map{|tmsat| tmsat.stop_area_type_id }
    stop_area_types = find([stop_area_type_ids])
    stop_area_types.map{ |stop_area_type| stop_area_type.code }
  end
  
end
