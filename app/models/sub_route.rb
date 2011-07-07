class SubRoute < ActiveRecord::Base
  has_many :route_sub_routes
  has_many :routes, :through => :route_sub_routes
  belongs_to :from_station, :class_name => 'StopArea'
  belongs_to :to_station, :class_name => 'StopArea'
  belongs_to :transport_mode
  has_many :campaigns, :as => :location, :order => 'created_at desc'
  has_many :problems, :as => :location, :order => 'created_at desc'
  has_friendly_id :name, :use_slug => true  
  attr_accessor :show_as_point
  is_route_or_sub_route
  is_location
  
  def points
    [from_station, to_station]
  end
  
  def transport_modes
    [TransportMode.find_by_name('Train')]
  end
  
  def terminuses
    points
  end
  
  def operators_responsible?
    true
  end
  
  def pte_responsible? 
    false
  end
  
  def councils_responsible? 
    false
  end
  
  def route_operators
    routes.map{ |route| route.operators }.flatten.uniq
  end
  
  def operators
    if route_operators.empty?
      mode = TransportMode.find_by_name('Train')
      operators = Operator.find(:all, :conditions => ['transport_mode_id = ?', mode.id], 
                                      :order => 'name asc')
    else
      operators = route_operators
    end
    operators
  end
  
  def responsible_organization_type
    :company
  end
  
  def responsible_organizations
    operators
  end
  
  def name
    name_by_terminuses(transport_mode, from_stop=nil, short=true)
  end
  
  def description
    name
  end
  
  def make_routes
    find_options = { :transport_modes => [TransportMode.find_by_name('Train').id],
                     :as_terminus => false }
    found_routes = Route.find_all_by_locations([from_station, to_station], find_options)  
    found_routes.each do |route|
      self.route_sub_routes.create!(:route => route)
    end
  end
  
  def self.make_sub_route(from_station, to_station, transport_mode, routes)
    exists = find(:first, :conditions => ['from_station_id = ? 
                                          AND to_station_id = ? 
                                          AND transport_mode_id = ?', 
                          from_station, to_station, transport_mode])
    return exists if exists
    created = create!({:from_station => from_station, 
                       :to_station => to_station, 
                       :transport_mode => transport_mode})
    routes.each do |route|
      RouteSubRoute.create!(:route => route, 
                            :sub_route => created)
    end
    return created
  end
end
