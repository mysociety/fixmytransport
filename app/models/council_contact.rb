class CouncilContact < ActiveRecord::Base
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  
  def name
    council_data = MySociety::MaPit.call('area', area_id)
    council_data['name']
  end
  
end
