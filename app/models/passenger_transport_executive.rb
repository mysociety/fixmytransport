class PassengerTransportExecutive < ActiveRecord::Base
  has_many :areas, :class_name => "PassengerTransportExecutiveArea"
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  has_many :pte_contacts, :class_name => 'PassengerTransportExecutiveContact',  
                          :foreign_key => 'passenger_transport_executive_id',
                          :conditions => ['deleted = ?', false]
  
  has_paper_trail
  
  def emailable?(location)
    conditions = ["category = 'Other' and (location_type = ? or location_type is null)", location.class.to_s]
    general_contacts = self.pte_contacts.find(:all, :conditions => conditions)
    return false if general_contacts.empty?
    return true
  end
  
  def categories(location)
    contacts = self.contacts_for_location_type(location.class.to_s)
    if contacts.empty?
      contacts = self.general_contacts
    end
    contacts.map{ |contact| contact.category }
  end
  
  def contact_for_category_and_location(category, location)
    location_contacts = self.contacts_for_location_type(location.class.to_s)
    if category_contact = self.contact_for_category(location_contacts, category)
      return category_contact
    elsif other_contact = self.contact_for_category(location_contacts, "Other")
      return other_contact
    else
      general_contacts = self.general_contacts
      if category_contact = contact_for_category(general_contacts, category)
        return category_contact
      elsif other_contact = contact_for_category(general_contacts, "Other")
        return other_contact
      else
        raise "No \"Other\" category contact for #{self.name} (PTE ID: #{self.id})"
      end
    end
  end
  
  def contact_for_category(contact_list, category)
    contact_list.detect{ |contact| contact.category == category }
  end
    
  def contacts_for_location_type(location_type)
    self.pte_contacts.find(:all, :conditions => ['location_type = ?', location_type])
  end
  
  def general_contacts
    self.pte_contacts.find(:all, :conditions => ['location_type is null'])
  end 
  
end
