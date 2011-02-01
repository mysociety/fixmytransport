class SubRoute < ActiveRecord::Base
  has_many :route_sub_routes
  has_many :routes, :through => :route_sub_routes
  belongs_to :from_station, :class_name => 'StopArea'
  belongs_to :to_station, :class_name => 'StopArea'
  belongs_to :transport_mode
  has_many :campaigns, :as => :location, :order => 'created_at desc'
  has_many :problems, :as => :location, :order => 'created_at desc'
  
  attr_accessor :show_as_point
  is_route_or_sub_route
  
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
  
  def operators
    route_operators = routes.map{ |route| route.operators }.flatten.uniq
    if route_operators.empty?
      mode = TransportMode.find_by_name('Train')
      route_operators = Operator.find(:all, :conditions => ['transport_mode_id = ?', mode.id], 
                                            :order => 'name asc')
    end
    route_operators
  end
  
  def responsible_organization_type
    :company
  end
  
  def responsible_organizations
    operators
  end
  
  def name
    name_by_terminuses(transport_mode)
  end
  
  def description
    name
  end
  
  def self.make_sub_route(from_station, to_station, transport_mode)
    exists = find(:first, :conditions => ['from_station_id = ? 
                                          AND to_station_id = ? 
                                          AND transport_mode_id = ?', 
                          from_station, to_station, transport_mode])
    return exists if exists
    created = create!({:from_station => from_station, 
                       :to_station => to_station, 
                       :transport_mode => transport_mode})
    return created
  end
end
