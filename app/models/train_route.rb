# == Schema Information
# Schema version: 20100707152350
#
# Table name: routes
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  number            :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  type              :string(255)
#  name              :string(255)
#  region_id         :integer
#  cached_slug       :string(255)
#  operator_code     :string(255)
#  loaded            :boolean
#

class TrainRoute < Route
  
  def self.find_existing(route)
    self.find_existing_train_routes(route)
  end
  
  # as train routes are named by terminus, they have more than one name, depending on how you
  # order the terminuses - if the first_letter param is given, it specifies that terminus names
  # starting with that letter should be given first
  def name(from_stop=nil, short=false, first_letter=nil)
    return self[:name] if !self[:name].blank?
    name_by_terminuses(transport_mode, from_stop=from_stop, short=short, first_letter=first_letter)
  end
  
  def description
    return cached_description if cached_description
    name
  end
  
  def self.match_terminus(route_segment, route, type)
    if type == :to
      (route_segment.to_terminus? && 
      (route.terminuses.include? route_segment.to_stop_area or 
      !route.stops_or_stations.include? route_segment.to_stop_area))
    elsif type == :from
      (route_segment.from_terminus? && 
      (route.terminuses.include? route_segment.from_stop_area or 
      !route.stops_or_stations.include? route_segment.from_stop_area))
    end
  end
  
end
