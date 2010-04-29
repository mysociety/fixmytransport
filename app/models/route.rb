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
  has_many :route_operators, :dependent => :destroy
  has_many :operators, :through => :route_operators, :uniq => true
  has_many :route_stops, :dependent => :destroy
  has_many :stops, :through => :route_stops, :uniq => true, :order => 'common_name asc'
  belongs_to :transport_mode
  validates_presence_of :number
  has_many :problems, :as => :location
  
  # Return routes with this number and transport mode that have a stop in common with 
  # the stop list given
  def self.find_all_by_number_and_common_stop(new_route)
    stop_codes = new_route.stop_codes
    routes = find(:all, :conditions => ['number = ? and transport_mode_id = ?', 
                                         new_route.number, new_route.transport_mode.id],
                        :include => { :route_stops => :stop })
    routes_with_same_stops = []
    routes.each do |route|
      route_stop_codes = route.stop_codes
      stop_codes_in_both = (stop_codes & route_stop_codes)
      if stop_codes_in_both.size > 0
        routes_with_same_stops << route
      end    
    end
    routes_with_same_stops
  end
  
  # Return routes with this transport mode whose stops are a superset or subset of the stop 
  # list given and whose terminuses are the same
  def self.find_all_by_terminuses_and_stop_set(new_route)
    stop_codes = new_route.stop_codes
    condition_string = 'transport_mode_id = ?' 
    params = [new_route.transport_mode_id]
    terminuses = new_route.route_stops.select{|route_stop| route_stop.terminus == true }
    joins = ''
    terminuses.each_with_index do |terminus,index|
      joins += " inner join route_stops rs#{index} on routes.id = rs#{index}.route_id"
      condition_string += " and rs#{index}.terminus = 't' and rs#{index}.stop_id = ?"
      params << terminus.stop.id
    end
    conditions = [condition_string] + params
    routes = find(:all, :joins => joins, 
                        :conditions => conditions, 
                        :include => { :route_stops => :stop })
    routes_with_same_stops = []
    routes.each do |route|
      route_stop_codes = route.stop_codes
      stop_codes_in_both = (stop_codes & route_stop_codes)
      next if stop_codes_in_both.size == 0
      if (stop_codes_in_both.size == stop_codes.size) or (stop_codes_in_both.size == route_stop_codes.size)
        routes_with_same_stops << Route.find(route.id)
      end    
    end
    routes_with_same_stops
  end
  
  def self.add!(route)
    existing_routes = find_existing(route)
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
          original.route_operators.build(:operator => route_operator.operator)
        end
      end
      duplicate.route_stops.each do |route_stop|
        if existing_route_stop = original.route_stops.detect { |existing| existing.stop == route_stop.stop }
          if existing_route_stop.terminus? and !route_stop.terminus?
            existing_route_stop.terminus = false
          end
        else
          original.route_stops.build(:stop => route_stop.stop, :terminus => route_stop.terminus)
        end
      end
      duplicate.destroy
    end
    original.save!
  end
  
  def name
    return "#{transport_mode_name} route #{number}"
  end

  def stop_codes
    route_stops.map{ |route_stop| route_stop.stop.atco_code }
  end

  def transport_mode_name
    transport_mode.name
  end
  
end
