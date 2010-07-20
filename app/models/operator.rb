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
  validates_presence_of :name
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$"), 
                              :if => Proc.new { |operator| !operator.email.blank? }
  accepts_nested_attributes_for :route_operators, :allow_destroy => true, :reject_if => :route_operator_invalid
  has_paper_trail
  cattr_reader :per_page
  @@per_page = 20
  
  # we only accept new or delete existing associations
  def route_operator_invalid(attributes)
    (attributes['_add'] != "1" and attributes['_destroy'] != "1") or attributes['route_id'].blank?
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
