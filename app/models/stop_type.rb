# == Schema Information
# Schema version: 20100707152350
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
#  sub_type    :string(255)
#

class StopType < ActiveRecord::Base
  has_many :transport_mode_stop_types
  has_many :transport_modes, :through => :transport_mode_stop_types
  @@modes_by_code = {}
  @@codes_by_mode = {}
  
  def self.codes
    connection.select_rows("SELECT DISTINCT description, code 
                            FROM stop_types 
                            ORDER BY code")
  end
  
  def self.sub_types 
    connection.select_rows("SELECT DISTINCT point_type, sub_type 
                            FROM stop_types
                            WHERE code = 'BCT'
                            ORDER BY sub_type")
  end
  
  def self.codes_for_transport_mode(transport_mode_id)
    calculate_hashes if @@codes_by_mode.empty? 
    codes = @@codes_by_mode[transport_mode_id]
  end
  
  def self.conditions_for_transport_mode(transport_mode_id)
    if transport_mode_id == TransportMode.find_by_name("Tram/Metro").id
      conditions = 'metro_stop = ?'
      params = [true]
    else
      codes = codes_for_transport_mode(transport_mode_id)
      conditions = 'stop_type in (?)'
      params = [codes.uniq]
    end
    return [conditions, params]
  end
  
  def self.calculate_hashes
    transport_mode_stop_types = TransportModeStopType.find(:all, :include => :stop_type)
    transport_mode_stop_types.each do |tmst|
      if ! @@codes_by_mode[tmst.transport_mode_id]
        @@codes_by_mode[tmst.transport_mode_id] = []
      end
      @@codes_by_mode[tmst.transport_mode_id] << tmst.stop_type.code
      if ! @@modes_by_code[tmst.stop_type.code]
        @@modes_by_code[tmst.stop_type.code] = []
      end
      @@modes_by_code[tmst.stop_type.code] << tmst.transport_mode_id
    end
  end
  
  def self.transport_modes_for_code(code)
    calculate_hashes if @@modes_by_code.empty?
    @@modes_by_code[code]
  end
  
end
