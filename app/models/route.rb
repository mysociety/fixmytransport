# == Schema Information
# Schema version: 20100506162135
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  type              :string(255)
#

class Route < ActiveRecord::Base
  has_many :route_operators, :dependent => :destroy
  has_many :operators, :through => :route_operators, :uniq => true
  has_many :route_segments, :dependent => :destroy
  has_many :from_stops, :through => :route_segments, :class_name => 'Stop' 
  has_many :to_stops, :through => :route_segments, :class_name => 'Stop'
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
                        :include => { :route_segments => [:from_stop, :to_stop] })
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
    from_terminus_clause = ''
    to_terminus_clause = ''
    condition_string = 'transport_mode_id = ?' 
    params = [transport_mode_id]
    joins = ''
    stops.each_with_index do |item,index|
      if as_terminus
        from_terminus_clause = "rs#{index}.from_terminus = 't' and"
        to_terminus_clause = "rs#{index}.to_terminus = 't' and"
      end
      if item.is_a? Array
        stop_id_criteria = "in (?)"
      else
        stop_id_criteria = "= ?"
      end
      joins += " inner join route_segments rs#{index} on routes.id = rs#{index}.route_id"
      condition_string += " and (#{from_terminus_clause} rs#{index}.from_stop_id #{stop_id_criteria})"
      condition_string += " or (#{to_terminus_clause} rs#{index}.to_stop_id #{stop_id_criteria})"
      params << item
      params << item
    end
    conditions = [condition_string] + params
    routes = find(:all, :joins => joins, 
                        :conditions => conditions, 
                        :include => { :route_segments => [:from_stop, :to_stop] }).uniq
  end
  
  # Return routes with this transport mode whose stops are a superset or subset of the stop 
  # list given and whose terminuses are the same
  def self.find_all_by_terminuses_and_stop_set(new_route)
    stop_codes = new_route.stop_codes
    routes = find_all_by_stops(new_route.terminuses, new_route.transport_mode_id, as_terminus=true)
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
      return [] if attributes[:route_number].blank?
      routes = find_all_by_number_and_transport_mode_id(attributes[:route_number], attributes[:transport_mode_id])
      if routes.size > 1 and ! attributes[:area].blank?
        return routes.select{ |route| route.in_area?(attributes[:area]) }
      end
    end
    routes
  end
  
  def self.find_all_by_number_and_transport_mode_id(route_number, transport_mode_id)
    find(:all, :conditions => ['lower(number) = ? and transport_mode_id = ?', 
                              route_number.downcase, transport_mode_id])
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
    duplicates.each{ |duplicate| merge_duplicate_route(duplicate, original) }
    original.save!
  end
  
  def self.merge_duplicate_route(duplicate, original)
    raise "Can't merge route with problems: #{duplicate.inspect}" if !duplicate.problems.empty?
    duplicate.route_operators.each do |route_operator|
      if ! original.route_operators.detect { |existing| existing.operator == route_operator.operator }
        original.route_operators.build(:operator => route_operator.operator)
      end
    end
    duplicate.route_segments.each do |route_segment|
      existing_route_segment = original.route_segments.detect do |existing| 
        direct_match = (existing.from_stop == route_segment.from_stop && existing.to_stop == route_segment.to_stop)
        reverse_match = (existing.to_stop == route_segment.from_stop && existing.from_stop == route_segment.to_stop)
        direct_match or reverse_match
      end
      if existing_route_segment 
        if existing_route_segment.from_terminus? and !route_segment.from_terminus?
          existing_route_segment.from_terminus = false
        end
        if existing_route_segment.to_terminus? and !route_segment.to_terminus?
          existing_route_segment.to_terminus = false
        end
      else
        original.route_segments.build(:from_stop => route_segment.from_stop, 
                                      :to_stop => route_segment.to_stop,
                                      :from_terminus => route_segment.from_terminus,
                                      :to_terminus => route_segment.to_terminus)
      end
    end
    duplicate.destroy
  end
  
  def name(from_stop=nil)
    return "#{transport_mode_name} route #{number}"
  end

  def stop_codes
    stops.map{ |stop| stop.atco_code }.uniq
  end
  
  def stop_area_codes
    stop_areas = stops.map{ |stop| stop.stop_areas }.flatten
    stop_areas.map{ |stop_area| stop_area.code }.uniq
  end

  def transport_mode_name
    transport_mode.name
  end
  
  def in_area?(area_name)
    areas.map{ |area| area.downcase }.include?(area_name.downcase)
  end
  
  def areas(all=true)
    if all or terminuses.empty? 
      route_stop_list = stops
    else
      route_stop_list = terminuses
    end
    areas = route_stop_list.map do |stop| 
      if stop.locality.parents.empty?
        stop.locality.name
      else
        stop.locality.parents.map{ |parent_locality| parent_locality.name }
      end
    end.flatten.uniq
    areas
  end
  
  def description
    "#{name} #{area}"
  end
  
  def stops
    route_segments.map{ |route_segment| [route_segment.from_stop, route_segment.to_stop] }.flatten.uniq
  end
  
  def display_route_segments
    route_segments
  end
  
  def terminuses
    from_terminuses = route_segments.select{ |route_segment| route_segment.from_terminus? }
    to_terminuses = route_segments.select{ |route_segment| route_segment.to_terminus? }
    terminuses = from_terminuses.map{ |segment| segment.from_stop } + to_terminuses.map{ |segment| segment.to_stop }
    terminuses
  end
  
  def area
    area = ''
    area_list = areas(all=false)
    if area_list.size > 1
      area = " between #{area_list.to_sentence}"
    else
      area = " in #{area_list.first}" if !area_list.empty?
    end
    return area
  end
  
end
