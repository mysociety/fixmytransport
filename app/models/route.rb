# == Schema Information
# Schema version: 20100420165342
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#

class Route < ActiveRecord::Base
  has_many :route_operators
  has_many :operators, :through => :route_operators
  has_many :route_stops
  has_many :stops, :through => :route_stops
  belongs_to :transport_mode
  validates_presence_of :number
  has_many :problems, :as => :location
  
  # Are there routes with this number and transport mode that have a stop in common with 
  # the stop list given
  def self.find_existing(attributes)
    stop_codes = attributes[:stop_codes]
    routes = self.find(:all, :conditions => ['number = ? and transport_mode_id = ?', 
                              attributes[:number], attributes[:transport_mode_id]],
                             :include => { :route_stops => :stop })
    routes_with_same_stops = []
    routes.each do |route|
      route_stop_codes = route.stops.map{ |stop| stop.atco_code }
      stop_codes_in_both = (stop_codes & route_stop_codes)
      if stop_codes_in_both.size > 0
        routes_with_same_stops << route
      end    
    end
    routes_with_same_stops
  end

  def transport_mode_name
    transport_mode.name
  end
  
end
