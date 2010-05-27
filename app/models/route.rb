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
  def self.find_all_by_number_and_common_stop(new_route, operator_id)
    stop_codes = new_route.stop_codes
    stop_area_codes = new_route.stop_area_codes
    routes = Route.find(:all, :conditions => ['number = ? 
                                         and transport_mode_id = ? 
                                         and route_operators.operator_id = ?', 
                                         new_route.number, new_route.transport_mode.id, operator_id],
                        :include => [{ :route_segments => [:from_stop, :to_stop] }, :route_operators])
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
    include_param = [{ :route_segments => [:from_stop, :to_stop] }]
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
      condition_string += " and ((#{from_terminus_clause} rs#{index}.from_stop_id #{stop_id_criteria})"
      condition_string += " or (#{to_terminus_clause} rs#{index}.to_stop_id #{stop_id_criteria}))"
      params << item
      params << item
    end
    conditions = [condition_string] + params
    routes = find(:all, :joins => joins, 
                        :conditions => conditions, 
                        :include => include_param).uniq
  end
  
  def self.find_existing_routes(new_route)
    operator_id = new_route.route_operators.first.operator.id
    find_all_by_number_and_common_stop(new_route, operator_id)
  end
  
  # Return train routes by the same operator that pass through the terminuses of this route, or
  # that have terminuses that this route passes through
  def Route.find_existing_train_routes(new_route)
    operator_id = new_route.route_operators.first.operator.id
    terminuses = new_route.terminuses
    stops = new_route.stops
    routes = []
    possible_routes = Route.find(:all, 
                                 :conditions => [ 'route_operators.operator_id = ?
                                                   and transport_mode_id = ?', 
                                                   operator_id, new_route.transport_mode_id],
                                 :include => [:route_operators, {:route_segments => [:from_stop, :to_stop]}])                                    
    possible_routes.each do |route|
      if route.terminuses.all?{ |terminus| stops.include? terminus } 
        routes << route
      end
      route_stops = route.stops
      if terminuses.all?{ |terminus| route_stops.include? terminus }
        routes << route
      end
    end
    routes
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
    Route.find_all_by_stops([first_stops, last_stops], attributes[:transport_mode_id])
  end
  
  def self.get_terminuses(route_name)
    if terminus_match = /^(.*)\sto\s(.*)$/.match(route_name)
      return [terminus_match[1], terminus_match[2]]
    else
      return nil
    end
  end
  
  def self.add!(route, verbose=false)
    puts "Adding #{route.number}" if verbose
    existing_routes = find_existing(route)
    if existing_routes.empty?
      route.save!
      return route
    end
    puts "got existing" if verbose
    original = existing_routes.first
    duplicates = existing_routes - [original] 
    merge_duplicate_route(route, original)
    puts "merging new" if verbose
    duplicates.each do |duplicate| 
      original = Route.find(original.id)
      puts "merging duplicates" if verbose
      if find_existing(duplicate).include? original
        merge_duplicate_route(duplicate, original) 
      end
    end
  end
  
  def unset_terminuses(stop_ids)
    RouteSegment.update_all("from_terminus = 'f'", ["route_id = ? and from_stop_id in (?)", id, stop_ids])
    RouteSegment.update_all("to_terminus = 'f'", ["route_id = ? and to_stop_id in (?)", id, stop_ids])
  end
  
  def self.merge_duplicate_route(duplicate, original)
    raise "Can't merge route with problems: #{duplicate.inspect}" if !duplicate.problems.empty?
    duplicate.route_operators.each do |route_operator|
      if ! original.route_operators.detect { |existing| existing.operator == route_operator.operator }
        original.route_operators.build(:operator => route_operator.operator)
      end
    end
    non_terminuses = []
    duplicate.route_segments.each do |route_segment|
      direct_match = original.route_segments.detect do |existing| 
        (existing.from_stop == route_segment.from_stop && existing.to_stop == route_segment.to_stop)
      end     
      if direct_match    
        non_terminuses << route_segment.from_stop.id if !route_segment.from_terminus?
        non_terminuses << route_segment.to_stop.id if !route_segment.to_terminus?
      else
        to_terminus = (route_segment.to_terminus? && (original.terminuses.include? route_segment.to_stop or !original.stops.include? route_segment.to_stop))
        from_terminus = (route_segment.from_terminus? && (original.terminuses.include? route_segment.from_stop or !original.stops.include? route_segment.from_stop))
        non_terminuses << route_segment.to_stop.id if !to_terminus          
        non_terminuses << route_segment.from_stop.id if !from_terminus
        original.route_segments.build(:from_stop => route_segment.from_stop, 
                                      :to_stop => route_segment.to_stop,
                                      :from_terminus => from_terminus,
                                      :to_terminus => to_terminus)
      end
    end
    original.unset_terminuses(non_terminuses)
    duplicate.destroy
    original.save!
  end
  
  def name(from_stop=nil, short=false)
    name = "#{number}"
    if from_stop
      return name
    else
      return "#{transport_mode_name} #{name}"
    end
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
    "#{name(stop=nil, short=true)} #{area(lowercase=true)}"
  end
  
  def stops
    route_segments.map{ |route_segment| [route_segment.from_stop, route_segment.to_stop] }.flatten.uniq
  end
  
  def display_route_segments
    route_segments
  end
  
  def next_stops(stop_id)
    incoming_segments = route_segments.select{ |route_segment| route_segment.from_stop_id == stop_id } 
    incoming_segments.map{ |route_segment| route_segment.to_stop }
  end
  
  def previous_stops(stop_id)
    outgoing_segments = route_segments.select{ |route_segment| route_segment.to_stop_id == stop_id }
    outgoing_segments.map{ |route_segment| route_segment.from_stop }
  end
  
  def terminuses
    from_terminuses = route_segments.select{ |route_segment| route_segment.from_terminus? }
    to_terminuses = route_segments.select{ |route_segment| route_segment.to_terminus? }
    terminuses = from_terminuses.map{ |segment| segment.from_stop } + to_terminuses.map{ |segment| segment.to_stop }
    terminuses.uniq
  end
  
  def area(lowercase=false)
    area = ''
    area_list = areas(all=false)
    if area_list.size > 1
      area = "Between #{area_list.to_sentence}"
    else
      area = "In #{area_list.first}" if !area_list.empty?
    end
    if lowercase
      area[0] = area.first.downcase
    end
    return area
  end
  
  def name_by_terminuses(transport_mode, from_stop=nil)
    is_loop = false
    if from_stop
      if terminuses.size > 1
        terminuses = self.terminuses.reject{ |terminus| terminus == from_stop }
      else
        is_loop = true
        terminuses = self.terminuses
      end
      terminuses = terminuses.map{ |terminus| terminus.name_without_suffix(transport_mode) }.uniq
      if terminuses.size == 1
        if is_loop
          "#{transport_mode.name} from #{terminuses.to_sentence}"
        else
          "#{transport_mode.name} to #{terminuses.to_sentence}"
        end
      else
        "#{transport_mode.name} between #{terminuses.sort.to_sentence}"
      end
    else
      terminuses = self.terminuses.map{ |terminus| terminus.name_without_suffix(transport_mode) }.uniq
      if terminuses.size == 1
        "#{transport_mode.name} from #{terminuses.to_sentence}"
      else
        "#{transport_mode.name} route between #{terminuses.sort.to_sentence}"     
      end
    end 
  end
  
end
