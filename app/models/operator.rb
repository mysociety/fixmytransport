# == Schema Information
# Schema version: 20100707152350
#
# Table name: operators
#
#  id              :integer         not null, primary key
#  code            :string(255)
#  name            :text
#  created_at      :datetime
#  updated_at      :datetime
#  short_name      :string(255)
#  email           :text
#  email_confirmed :boolean
#  notes           :text
#

class Operator < ActiveRecord::Base
  has_many :route_operators, :dependent => :destroy
  has_many :routes, :through => :route_operators, :uniq => true, :order => 'routes.number asc'
  has_many :vosa_licenses
  has_many :operator_codes
  has_many :stop_area_operators, :dependent => :destroy
  has_many :stop_areas, :through => :stop_area_operators, :dependent => :destroy, :uniq => true
  belongs_to :transport_mode
  validates_presence_of :name
  has_many :operator_contacts, :conditions => ['deleted = ?', false]
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$"), 
                              :if => Proc.new { |operator| !operator.email.blank? }
  accepts_nested_attributes_for :route_operators, :allow_destroy => true, :reject_if => :route_operator_invalid
  has_paper_trail
  cattr_reader :per_page
  @@per_page = 20
  named_scope :with_email, :conditions => ["email is not null and email != ''"]
  named_scope :without_email, :conditions => ["email is null or email = ''"]
  has_friendly_id :name, :use_slug => true
  
  # we only accept new or delete existing associations
  def route_operator_invalid(attributes)
    (attributes['_add'] != "1" and attributes['_destroy'] != "1") or attributes['route_id'].blank?
  end
  
  def emailable?(location)
    general_contacts = self.operator_contacts.find(:all, :conditions => ["category = 'Other' 
                                                                          AND (location_id is null 
                                                                          OR (location_id = ?
                                                                          AND location_type = ?))", 
                                                                          location.id, location.class.to_s])
    return false if general_contacts.empty?
    return true
  end
  
  def contacts_for_location(location)
    self.operator_contacts.find(:all, :conditions => ['location_id = ? 
                                                       AND location_type = ?', 
                                                       location.id, location.class.to_s])
  end
  
  def general_contacts
    self.operator_contacts.find(:all, :conditions => ['location_id is null 
                                                       AND location_type is null'])
  end
  
  def categories(location)
    contacts = self.contacts_for_location(location)
    if contacts.empty?
      contacts = self.general_contacts
    end
    contacts.map{ |contact| contact.category }
  end
  
  def contact_for_category(contact_list, category)
    contact_list.detect{ |contact| contact.category == category }
  end
  
  # return the appropriate contact for a particular type of problem
  def contact_for_category_and_location(category, location)
    location_contacts = self.contacts_for_location(location)
    if category_contact = contact_for_category(location_contacts, category)
      return category_contact
    elsif other_contact = contact_for_category(location_contacts, "Other")
      return other_contact
    else
      general_contacts = self.general_contacts
      if category_contact = contact_for_category(general_contacts, category)
        return category_contact
      elsif other_contact = contact_for_category(general_contacts, "Other")
        return other_contact
      else
        raise "No \"Other\" category contact for #{self.name} (operator ID: #{self.id})" 
      end
    end
  end
  
  def emails
    self.operator_contacts.map{ |contact| contact.email }.uniq.compact
  end
  
  def self.find_all_by_nptdr_code(vehicle_code, code, region)
    vehicle_modes, similar_vehicle_modes = vehicle_codes_to_noc_vehicle_modes(vehicle_code)
    operators = find(:all, :include => :operator_codes, 
                           :conditions => ['vehicle_mode in (?) 
                                            AND operator_codes.code = ?
                                            AND operator_codes.region_id = ?', 
                                            vehicle_modes, code, region])
    # try specific lookups
    if operators.empty?
      if vehicle_code == 'T'
        operators = find(:all, :conditions => ["vehicle_mode in (?)
                                                AND noc_code = ?", vehicle_modes, "=#{code}"])
      end
      #  There's a missing trailing number from Welsh codes ending in '00' in 2009 NPTDR
      if /[A-Z][A-Z]00/.match(code) and vehicle_code == 'B'
        # find any code in the region that consists of the truncated code plus one other character
        code_with_wildcard = "#{code}_"
        operators = find(:all, :conditions => ["vehicle_mode in (?)
                                                AND operator_codes.code like ?
                                                AND region_id = ?", 
                                                vehicle_modes, code_with_wildcard, Region.find_by_name('Wales')],
                               :include => :operator_codes)
      end
    end 
    
    if operators.empty?
      # if no operators, add any operators with this code with the right vehicle mode    
      operators = find(:all, :conditions => ["vehicle_mode in (?)
                                              AND operator_codes.code = ?", 
                                              vehicle_modes, code],
                             :include => :operator_codes)
    end
    if operators.empty? 
      # look for the code in the region with a similar vehicle mode
      operators = find(:all, :conditions => ["vehicle_mode in (?)
                                              AND operator_codes.code = ?
                                              AND region_id = ?", 
                                              similar_vehicle_modes, code, region], 
                             :include => :operator_codes)
    end
    
    operators
  end
  
  def self.vehicle_mode_to_transport_mode(vehicle_mode)
    modes_to_modes = {  'bus'         => 'Bus',
                        'coach'       => 'Coach',
                        'drt'         => 'Bus',
                        'ferry'       => 'Ferry',
                        'metro'       => 'Tram/Metro',
                        'other'       => 'Bus',
                        'rail'        => 'Train',
                        'tram'        => 'Tram/Metro',
                        'underground' => 'Tram/Metro' }
    TransportMode.find_by_name(modes_to_modes[vehicle_mode.downcase])                    
  end
  
  # mapping from NPTDR vehicle codes to NOC vehicle modes 
  def self.vehicle_codes_to_noc_vehicle_modes(vehicle_code)
    codes_to_modes = { 'T' => [['Rail'], []], 
                       'B' => [['Bus'], ['Coach', 'DRT']], 
                       'C' => [['Coach'], ['Bus', 'DRT']], 
                       'M' => [['Metro', 'Underground', 'Tram'], []], 
                       'A' => [['Air'], []], 
                       'F' => [['Ferry'], []]}
    vehicle_mode_list = codes_to_modes[vehicle_code]
  end
  
  # merge operator records to merge_to, transferring associations
  def self.merge!(merge_to, operators)
    transaction do
      operators.each do |operator|
        next if operator == merge_to
        operator.route_operators.each do |route_operator|
          merge_to.route_operators.build(:route => route_operator.route)
        end
        if !operator.email.blank? and merge_to.email.blank?
          merge_to.email = operator.email
          merge_to.email_confirmed = operator.email_confirmed
        end
        operator.destroy
      end
      merge_to.save!
    end
  end
  
end
