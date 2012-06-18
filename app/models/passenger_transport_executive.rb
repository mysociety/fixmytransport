class PassengerTransportExecutive < ActiveRecord::Base
  has_many :areas, :class_name => "PassengerTransportExecutiveArea"
  has_many :pte_contacts, :class_name => 'PassengerTransportExecutiveContact',
                          :foreign_key => :passenger_transport_executive_persistent_id,
                          :primary_key => :persistent_id,
                          :conditions => ['deleted = ?', false]
  has_many :responsibilities, :as => :organization
  validate :name_unique_in_generation
  has_paper_trail

  def self.statuses
    { 'ACT' => 'Active',
      'DEL' => 'Deleted' }
  end

  validates_inclusion_of :status, :in => self.statuses.keys

  # This model is part of the transport data that is versioned by data generations.
  # This means they have a default scope of models valid in the current data generation.
  # See lib/fixmytransport/data_generations
  exists_in_data_generation( :identity_fields => [],
                             :descriptor_fields => [:name] )


  # this is a custom validation as names need only be unique within the data generation bounds
  # set by the default scope. Allows blank values
  def name_unique_in_generation
   self.field_unique_in_generation(:name)
  end

  def emailable?(location)
    return false if self.status == 'DEL'
    conditions = ["category = 'Other' and (location_type = ? or location_type is null or location_type = '')",
                  location.class.to_s]
    general_contacts = self.pte_contacts.find(:all, :conditions => conditions)
    return false if general_contacts.empty?
    return true
  end

  def emails
    self.pte_contacts.map{ |contact| contact.email }.uniq.compact
  end

  def categories(location)
    contacts = contacts_for_location_type(location.class.to_s)
    if contacts.empty?
      contacts = general_contacts
    end
    contacts.map{ |contact| contact.category }
  end

  def contact_for_category_and_location(category, location)
    location_contacts = contacts_for_location_type(location.class.to_s)
    if category_contact = self.contact_for_category(location_contacts, category)
      return category_contact
    elsif other_contact = self.contact_for_category(location_contacts, "Other")
      return other_contact
    else
      general_contacts_list = general_contacts
      if category_contact = contact_for_category(general_contacts_list, category)
        return category_contact
      elsif other_contact = contact_for_category(general_contacts_list, "Other")
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
    self.pte_contacts.find(:all, :conditions => ["location_type is null or location_type = ''"])
  end

  private :contacts_for_location_type, :general_contacts

end
