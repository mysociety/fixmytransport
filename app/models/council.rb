class Council

  attr_accessor :name, :id

  def initialize(attributes)
    @id = attributes[:id]
    @name = attributes[:name]
  end

  def self.from_hash(attributes)
    return self.new(:id => attributes['id'],
                    :name => attributes['name'])
  end
  
  def ==(other)
    (other.is_a?(Council)) && (@id == other.id) && (@name == other.name)
  end

  def emailable?(location)
    !self.contacts.empty?
  end

  def categories(location)
    categories = contacts.map{ |contact| contact.category }
  end

  def contacts_for_location(location)
    district_contacts = self.contacts.select{ |contact| !contact.district_id.nil? }
    return [] if district_contacts.empty?
    district_id = Council.get_district_id(location)
    return [] unless district_id
    return district_contacts.select{ |contact| contact.district_id == district_id }
  end

  def general_contacts
    self.contacts.select{ |contact| contact.district_id.nil? }
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
        raise "No \"Other\" category contact for #{self.name} (area ID: #{self.id})"
      end
    end
  end

  def emails
    emails = contacts.map{ |contact| contact.email }.uniq.compact
  end

  def contacts
    CouncilContact.find(:all, :conditions => ['area_id = ? and deleted = ?', self.id, false])
  end

  def get_districts()
  end

  def self.get_district_id(location)
    district_id = MySociety::MaPit.call('point', "4326/#{location.lon},#{location.lat}", {:type => 'DIS'})
    district_id.keys.first.nil? ? nil : district_id.keys.first.to_i
  end

  def self.find_by_id(id)
    council_data = MySociety::MaPit.call("area", id)
    council = Council.from_hash(council_data)
  end

  def self.find_all_without_ptes
    council_parent_types = MySociety::VotingArea.va_council_parent_types
    pte_area_ids = PassengerTransportExecutiveArea.find(:all).map{ |area| area.area_id }
    council_data = MySociety::MaPit.call("areas", "#{council_parent_types.join(',')}")
    council_data = council_data.values.reject{ |council_info| pte_area_ids.include? council_info['id'] }
    councils = council_data.map{ |council_info| Council.from_hash(council_info) }
    councils = councils.sort_by(&:name)
  end

end