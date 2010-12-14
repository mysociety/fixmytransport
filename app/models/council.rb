class Council
  
  attr_accessor :name, :id, :emailable
  
  def initialize(attributes)
    @id = attributes[:id]
    @name = attributes[:name]
  end
  
  def self.from_hash(attributes)
    return self.new(:id => attributes['id'], 
                    :name => attributes['name'])
  end
  
  def emailable? 
    @emailable
  end
  
  # return the appropriate contact for a particular type of problem
  def contact_for_category(category)
    if category_contact = contacts.detect{ |contact| contact.category == category }
      return category_contact
    elsif other_contact = contacts.detect{ |contact| contact.category == 'Other' }
      return other_contact
    else
      raise "No \"Other\" category contact for #{self.name} (area ID: #{self.id})" 
    end
  end
  
  def emails
    emails = contacts.map{ |contact| contact.email }.uniq.compact
  end
  
  def contacts
    CouncilContact.find(:all, :conditions => ['area_id = ?', self.id])
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