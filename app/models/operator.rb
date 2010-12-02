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
  has_many :routes, :through => :route_operators, :uniq => true
  has_many :vosa_licenses
  has_many :operator_codes
  has_many :sent_emails, :as => :recipient
  has_many :outgoing_messages, :as => :recipient
  validates_presence_of :name
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$"), 
                              :if => Proc.new { |operator| !operator.email.blank? }
  accepts_nested_attributes_for :route_operators, :allow_destroy => true, :reject_if => :route_operator_invalid
  has_paper_trail
  cattr_reader :per_page
  @@per_page = 20
  named_scope :with_email, :conditions => ["email is not null and email != ''"]
  named_scope :without_email, :conditions => ["email is null or email = ''"]
  
  # we only accept new or delete existing associations
  def route_operator_invalid(attributes)
    (attributes['_add'] != "1" and attributes['_destroy'] != "1") or attributes['route_id'].blank?
  end
  
  def emailable?
    !email.blank?
  end
  
  def self.find_all_by_nptdr_code(vehicle_code, code, region)
    vehicle_modes = vehicle_codes_to_noc_vehicle_modes(vehicle_code)
    operators = find(:all, :include => :operator_codes, 
                           :conditions => ['vehicle_mode in (?) 
                                            AND operator_codes.code = ?
                                            AND operator_codes.region_id = ?', 
                                            vehicle_modes, code, region])
    # try specific lookups
    if operators.empty?
      if vehicle_code == 'T'
        operators = find(:all, :conditions => ["vehicle_mode in (?)
                                                AND noccode = ?", vehicle_modes, "=#{code}"])
      end
      #  There's a missing trailing number from Welsh codes ending in '00' in 2009 NPTDR
      if /[A-Z][A-Z]00/.match(code) and vehicle_code == 'B'
        # find any code in the region that consists of the truncated code plus one other character
        code_with_wildcard = "#{code}_"
        operators = find(:all, :conditions => ["vehicle_mode in (?)
                                                AND operator_codes.code like ?
                                                AND region_id = ?", 
                                                vehicle_modes, code_with_wildcard, region],
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
    operators
  end
  
  # mapping from NPTDR vehicle codes to NOC vehicle modes 
  def self.vehicle_codes_to_noc_vehicle_modes(vehicle_code)
    codes_to_modes = { 'T' => ['Rail'], 
                       'B' => ['Bus'], 
                       'C' => ['Coach'], 
                       'M' => ['Metro', 'Underground', 'Tram'], 
                       'A' => ['Air'], 
                       'F' => ['Ferry'] }
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
