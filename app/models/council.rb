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
    contacts = CouncilContact.find(:all, :conditions => ['area_id = ?', self.id])
    if category_contact = contacts.detect{ |contact| contact.category == category }
      return category_contact
    elsif other_contact = contacts.detect{ |contact| contact.category == 'Other' }
      return other_contact
    else
      raise "No \"Other\" category contact for #{self.name} (area ID: #{self.id})" 
    end
  end
  
  def emails
    contacts = CouncilContact.find(:all, :conditions => ['area_id = ?', self.id])
    emails = contacts.map{ |contact| contact.email }.uniq.compact
  end

end