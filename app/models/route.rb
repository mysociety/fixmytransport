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
  
  def self.find_existing(attributes)
    stop_codes = attributes[:stop_codes]
    routes = self.find(:all, :conditions => ['number = ? and transport_mode_id = ?', 
                              attributes[:number], attributes[:transport_mode_id]],
                             :include => { :route_stops => :stop })
    routes_with_same_stops = []
    routes.each do |route|
      route_stop_codes = route.stops.map{ |stop| stop.atco_code }
      # are the stop code lists identical?
      if route_stop_codes.size == stop_codes.size && stop_codes.size == (stop_codes & route_stop_codes).size
        routes_with_same_stops << route
      end
    end
    routes_with_same_stops
  end
end
