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
  
  # Return routes with this number and transport mode that have a stop or stop area in common with 
  # the route given
  def self.find_all_by_number_and_common_stop(new_route)
    stop_codes = new_route.stop_codes
    stop_area_codes = new_route.stop_area_codes
    routes = find(:all, :conditions => ['number = ? and transport_mode_id = ?', 
                                         new_route.number, new_route.transport_mode.id],
                        :include => { :route_stops => :stop })
    routes_with_same_stops = []
    routes.each do |route|
      route_stop_codes = route.stop_codes
      stop_codes_in_both = (stop_codes & route_stop_codes)
      if stop_codes_in_both.size > 0
        routes_with_same_stops << route
        next
      end  
      route_stop_area_codes = route.stop_area_codes
      stop_area_codes_in_both = (stop_area_codes & route_stop_area_codes)
      if stop_area_codes_in_both.size > 0
        routes_with_same_stops << route
      end
    end
    routes_with_same_stops
  end
  
  # Accepts an array of stops or an array of arrays of stops as first parameter.
  # If passed the latter, will find routes that pass through at least one stop in
  # each array. 
  def self.find_all_by_stops(stops, transport_mode_id, as_terminus=false)
    terminus_clause = ''
    condition_string = 'transport_mode_id = ?' 
    params = [transport_mode_id]
    joins = ''
    stops.each_with_index do |item,index|
      if as_terminus
        terminus_clause = "and rs#{index}.terminus = 't'"
      end
      if item.is_a? Array
        stop_id_criteria = "in (?)"
      else
        stop_id_criteria = "= ?"
      end
      joins += " inner join route_stops rs#{index} on routes.id = rs#{index}.route_id"
      condition_string += " #{terminus_clause} and rs#{index}.stop_id #{stop_id_criteria}"
      params << item
    end
    conditions = [condition_string] + params
    routes = find(:all, :joins => joins, 
                        :conditions => conditions, 
                        :include => { :route_stops => :stop }).uniq
  end
  
  # Return routes with this transport mode whose stops are a superset or subset of the stop 
  # list given and whose terminuses are the same
  def self.find_all_by_terminuses_and_stop_set(new_route)
    stop_codes = new_route.stop_codes
    terminuses = new_route.route_stops.select{|route_stop| route_stop.terminus == true }
    stops = terminuses.map{ |route_stop| route_stop.stop }
    routes = find_all_by_stops(stops, new_route.transport_mode_id, as_terminus=true)
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
  
  def self.find_from_attributes(attributes)
    if terminuses = get_terminuses(attributes[:route_number])
      first, last = terminuses
      routes = find_all_by_stop_names(first, last, attributes)
    else
      routes = find_all_by_number_and_transport_mode_id(attributes[:route_number], attributes[:transport_mode_id])
    end
  end
  
  def self.find_all_by_stop_names(first, last, attributes)
    first_stops = Stop.find_from_attributes(attributes.merge(:name => first))
    last_stops = Stop.find_from_attributes(attributes.merge(:name => last))
    find_all_by_stops([first_stops, last_stops], attributes[:transport_mode_id])
  end
  
  def self.get_terminuses(route_name)
    if terminus_match = /^(.*)\sto\s(.*)$/.match(route_name)
      return [terminus_match[1], terminus_match[2]]
    else
      return nil
    end
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
  
  def name(from_stop=nil)
    return "#{transport_mode_name} route #{number}"
  end

  def stop_codes
    route_stops.map{ |route_stop| route_stop.stop.atco_code }.uniq
  end
  
  def stop_area_codes
    stop_areas = route_stops.map{ |route_stop| route_stop.stop.stop_areas }.flatten
    stop_areas.map{ |stop_area| stop_area.code }.uniq
  end

  def transport_mode_name
    transport_mode.name
  end
  
  def area
    areas = stops.map{ |stop| stop.parent_locality_name if !stop.parent_locality_name.blank? }.compact.uniq
    coverage = areas.to_sentence
    coverage = " in #{coverage}" if !coverage.blank?
    return coverage
  end
  
end
