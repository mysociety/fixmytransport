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
  has_many :operators, :through => :route_operators, :uniq => true
  has_many :route_stops
  has_many :stops, :through => :route_stops, :uniq => true, :order => 'common_name asc'
  belongs_to :transport_mode
  validates_presence_of :number
  has_many :problems, :as => :location
  
  # Return routes with this number and transport mode that have a stop in common with 
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
  
  def self.add!(route)
    route_attributes = { :number => route.number, 
                         :transport_mode_id => route.transport_mode.id, 
                         :stop_codes => route.route_stops.map{ |route_stop| route_stop.stop.atco_code } }
    existing_routes = find_existing(route_attributes)
    if existing_routes.empty?
      route.save!
      return route
    end
    original = existing_routes.first
    duplicates = existing_routes - [original] 
    duplicates += [route]
    duplicates.each do |duplicate|
      if !duplicate.problems.empty?
        raise "Can't merge route with problems: #{duplicates.inspect}"
      end
      duplicate.route_operators.each do |route_operator|
        if ! original.route_operators.detect { |existing| existing.operator == route_operator.operator }
          original.route_operators << route_operator
        end
      end
      duplicate.route_stops.each do |route_stop|
        if existing = original.route_stops.detect { |existing| existing.stop == route_stop.stop }
          if existing.terminus? and !route_stop.terminus?
            existing.terminus = false
          end
        else
          original.route_stops << route_stop
        end
      end
      duplicate.destroy
    end
    original.save!
  end

  def transport_mode_name
    transport_mode.name
  end
  
end
