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

  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generations
  exists_in_data_generation( :identity_fields => [:noc_code],
                             :new_record_fields => [:name, :transport_mode_id],
                             :update_fields => [:vosa_license_name,
                                                :parent,
                                                :ultimate_parent,
                                                :vehicle_mode],
                             :temporary_identity_fields => [:id],
                             :auto_update_fields => [:cached_slug])

  has_many :route_operators, :dependent => :destroy
  has_many :routes, :through => :route_operators, :uniq => true, :order => 'routes.number asc'
  has_many :stop_area_operators, :dependent => :destroy
  has_many :stop_areas, :through => :stop_area_operators, :uniq => true
  has_many :stop_operators, :dependent => :destroy
  has_many :stops, :through => :stop_operators, :uniq => true

  has_many :vosa_licenses
  has_many :operator_codes
  belongs_to :transport_mode
  has_many :operator_contacts, :conditions => ['deleted = ?', false],
                               :foreign_key => :operator_persistent_id,
                               :primary_key => :persistent_id,
                               :dependent => :destroy
  has_many :responsibilities, :foreign_key => :organization_persistent_id,
                              :primary_key => :persistent_id
  validates_presence_of :name
  validate :noc_code_unique_in_generation

  accepts_nested_attributes_for :route_operators, :allow_destroy => true, :reject_if => :route_operator_invalid
  has_paper_trail :meta => { :replayable  => Proc.new { |operator| operator.replayable } }
  cattr_reader :per_page
  @@per_page = 20
  has_friendly_id :name, :use_slug => true

  # this is a custom validation as noc codes need only be unique within the data generation bounds
  # set by the default scope. Allows blank values
  def noc_code_unique_in_generation
    self.field_unique_in_generation(:noc_code)
  end

  # we only accept new or delete existing associations
  def route_operator_invalid(attributes)
    (attributes['_add'] != "1" and attributes['_destroy'] != "1") or attributes['route_id'].blank?
  end

  def emailable?(location)
    general_contacts = self.operator_contacts.find(:all, :conditions => ["category = 'Other'
                                                                          AND (location_persistent_id is null
                                                                          OR (location_persistent_id = ?
                                                                          AND location_type = ?))",
                                                                          location.persistent_id, location.class.to_s])
    return false if general_contacts.empty?
    return true
  end

  def contacts_for_location(location)
    self.operator_contacts.find(:all, :conditions => ['location_persistent_id = ?
                                                       AND location_type = ?',
                                                       location.persistent_id, location.class.to_s])
  end

  def general_contacts
    self.operator_contacts.find(:all, :conditions => ["location_persistent_id is null
                                                       AND (location_type is null
                                                       OR location_type = '')"])
  end

  def codes
    operator_codes.map{ |operator_code| operator_code.code }.uniq
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
  def contact_for_category_and_location(category, location, exception_on_fail=true)
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
        if exception_on_fail
          raise "No \"Other\" category contact for #{self.name} (operator ID: #{self.id})"
        else
          return nil
        end
      end
    end
  end

  def emails
    self.operator_contacts.map{ |contact| contact.email }.uniq.compact
  end

  def problem_count(visible_only=false)
    conditions = ["id in (SELECT problem_id
                          FROM responsibilities
                          WHERE organization_type = 'Operator'
                          AND organization_persistent_id = ?)", self.id]
    if visible_only
      Problem.visible.count(:conditions => conditions)
    else
      Problem.count(:conditions => conditions)
    end
  end

  def campaign_count(visible_only=false)
    conditions = ["id in (SELECT campaign_id FROM problems
                          WHERE problems.id in (SELECT problem_id
                                                FROM responsibilities
                                                WHERE organization_type = 'Operator'
                                                AND organization_persistent_id = ?))", self.id]
    if visible_only
      Campaign.visible.count(:conditions => conditions)
    else
      Campaign.count(:conditions => conditions)
    end
  end

  def self.count_without_contacts
    count(:conditions => ['persistent_id not in (select operator_persistent_id from operator_contacts where deleted = ?)', false])
  end

  def self.find_all_by_nptdr_code(transport_mode, code, region, route)
    operators = find(:all, :include => :operator_codes,
                           :conditions => ['transport_mode_id = ?
                                            AND operator_codes.code = ?
                                            AND operator_codes.region_id = ?',
                                            transport_mode, code, region])
    # try specific lookups
    if operators.empty?
      if transport_mode.name == 'Train'
        operators = find(:all, :conditions => ["transport_mode_id = ?
                                                AND noc_code = ?", transport_mode, "=#{code}"])
      end
    end

    if operators.empty?
      # if no operators, add any operators with this code with the right transport_mode in a region the route
      # goes through
      regions = route.stops.map{ |stop| stop.locality.admin_area.region }.uniq
      operators = find(:all, :conditions => ["transport_mode_id = ?
                                              AND operator_codes.code = ?
                                              AND region_id in (?)",
                                              transport_mode, code, regions],
                             :include => :operator_codes)
    end
    if operators.empty?
      if similar = self.similar_mode(transport_mode)
        # look for the code in the region with a similar transport_mode
        operators = find(:all, :conditions => ["transport_mode_id = ?
                                                AND operator_codes.code = ?
                                                AND region_id = ?",
                                                similar, code, region],
                               :include => :operator_codes)
      end
    end

    # # try any operators with that code
    if (transport_mode.name == 'Train' || transport_mode.name == 'Coach') && operators.empty?
      operators = find(:all, :include => :operator_codes,
                             :conditions => ['transport_mode_id = ?
                                              AND operator_codes.code = ?',
                                              transport_mode, code])
    end
    operators
  end

  def normalize_name(name)
    normalized_name = name.downcase
    normalized_name = normalized_name.gsub(/\(.*\)/, '')
    normalized_name = normalized_name.gsub(/,.*/, '')
    normalized_name = normalized_name.gsub(/[^a-z]/, "")
    normalized_name = normalized_name.gsub(/(limited|ltd)/, '')
    normalized_name
  end

  # Loose comparison method for names to short names from other data
  # sources - accepts an extra parameter for the length at which the
  # name passed for comparison has been cropped
  def matches_short_name?(comparison_name, comparison_max_length=nil)
    check_cropped = false
    if comparison_max_length && comparison_name.length == comparison_max_length
      check_cropped = true
    end
    comparison_name = normalize_name(comparison_name)
    if self.short_name
      return true if self.normalize_name(self.short_name) == comparison_name
      if check_cropped
        return true if self.normalize_name(self.short_name[0 ,comparison_max_length]) == comparison_name
      end
    end
    return true if self.normalize_name(self.name) == comparison_name
    if check_cropped
      return true if self.normalize_name(self.name[0, comparison_max_length]) == comparison_name
    end
    return false
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

  def self.similar_mode(transport_mode)
    similar = { 'Bus' => 'Coach',
                'Coach' => 'Bus' }
    if similar_mode_name = similar[transport_mode.name]
      return TransportMode.find_by_name(similar_mode_name)
    else
      return nil
    end
  end

  # merge operator records to merge_to, transferring associations
  # NB: This merge method doesn't transfer contacts.
  def self.merge!(merge_to, operators)
    transaction do
      operators.each do |operator|
        raise "Can't merge operator with responsibilities: #{operator.name} (#{operator.id})" if operator.problem_count > 0
        next if operator == merge_to
        operator.route_operators.each do |route_operator|
          if ! merge_to.route_operators.detect { |existing| existing.route == route_operator.route }
            merge_to.route_operators.build(:route => route_operator.route)
          end
        end
        operator.stop_area_operators.each do |stop_area_operator|
          if ! merge_to.stop_area_operators.detect { |existing| existing.stop_area == stop_area_operator.stop_area }
            merge_to.stop_area_operators.build(:stop_area => stop_area_operator.stop_area)
          end
        end
        operator.stop_operators.each do |stop_operator|
          if ! merge_to.stop_operators.detect { |existing| existing.stop == stop_operator.stop }
            merge_to.stop_operators.build(:stop => stop_operator.stop)
          end
        end
        operator.operator_codes.each do |operator_code|
          if ! merge_to.operator_codes.detect { |existing| existing.code == operator_code.code && existing.region_id == operator_code.region_id }
            merge_to.operator_codes.build(:code => operator_code.code,
                                          :region_id => operator_code.region_id)
          end
        end
        operator.vosa_licenses.each do |vosa_license|
          if ! merge_to.vosa_licenses.detect { |existing| existing.number == vosa_license.number }
            merge_to.vosa_licenses.build(:number => vosa_license.number)
          end
        end
        operator.destroy
        MergeLog.create!(:from_id => operator.id,
                         :to_id => merge_to.id,
                         :model_name => 'Operator')
      end
      merge_to.save!

    end
  end

  def self.problems_at_location(location_type, location_id, operator_id)
    location = location_type.constantize.find(location_id)
    operator = Operator.find(operator_id)
    conditions = ["problems.location_type = ?
                   AND problems.location_persistent_id = ?
                   AND responsibilities.organization_persistent_id = ?
                   AND responsibilities.organization_type = 'Operator'",
                  location_type, location.persistent_id, operator.persistent_id]
    return Problem.find(:all, :conditions => conditions, :include => :responsibilities)
  end

  def self.all_by_letter
    MySociety::Util.by_letter(Operator.find(:all), :upcase){|o| o.name }
  end

  def self.all_letters
    all_by_letter.keys.sort
  end

  # slightly ugly syntax for class methods
  class << self; extend ActiveSupport::Memoizable; self; end.memoize :all_by_letter, :all_letters

end
