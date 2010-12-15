# == Schema Information
# Schema version: 20100707152350
#
# Table name: location_searches
#
#  id                :integer         not null, primary key
#  transport_mode_id :integer
#  name              :string(255)
#  area              :string(255)
#  route_number      :string(255)
#  location_type     :string(255)
#  session_id        :string(255)
#  events            :text
#  active            :boolean
#  created_at        :datetime
#  updated_at        :datetime
#

class LocationSearch < ActiveRecord::Base
  
  serialize :events
  belongs_to :transport_mode
  
  def self.find_current(session_id)
    find(:first, :conditions => ['session_id = ? and active = ?', session_id, true], 
                 :order => 'created_at desc')
  end
  
  def self.close_session_searches(session_id)
    searches = find(:all, :conditions => ['session_id = ? and active = ?', session_id, true])
    searches.each { |search| search.toggle!(:active) }
  end
  
  def self.new_search!(session_id, params)
    close_session_searches(session_id)
    attributes = { :name              => params[:name], 
                   :route_number      => params[:route_number], 
                   :area              => params[:area],
                   :transport_mode_id => params[:transport_mode_id],
                   :location_type     => params[:location_type], 
                   :from              => params[:from],
                   :to                => params[:to] }
    attributes[:session_id] = session_id
    attributes[:active] = true
    attributes[:events] = []
    create(attributes)
  end
  
  def description
    descriptors = []
    descriptors << transport_mode.name if transport_mode
    descriptors << location_type.tableize.singularize.humanize.downcase if location_type
    if !route_number.blank?
      descriptors << "route '#{route_number}'"
    end
    if !name.blank?
      descriptors << "called/in '#{name}'"
    end
    if !from.blank?
      descriptors << "from #{from}"
    end
    if !to.blank?
      descriptors << "to #{to}"
    end
    if !area.blank?
      descriptors << "in #{area}"
    end
    descriptors.join(' ')
  end
  
  def add_choice(locations)
    self.events << { :type => :choice, 
                     :locations => locations.size,
                     :location_type => locations.first.class.to_s } 
    self.save
  end
  
  def add_location(location)
    self.events << { :type => :result, 
                     :location => identifying_info(location) }
    self.save
  end
  
  def add_method(method)
    self.events << { :type => :method, 
                     :method => method }
    self.save
  end
  
  def fail()
    self.failed = true
    self.save
    self.close()
  end
  
  def close
    LocationSearch.close_session_searches(session_id)
  end
  
  def identifying_info(location)
    { :id => location.id, :class => location.class.to_s }
  end
  
end
