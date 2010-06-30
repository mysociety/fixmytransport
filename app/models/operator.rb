# == Schema Information
# Schema version: 20100506162135
#
# Table name: operators
#
#  id         :integer         not null, primary key
#  code       :string(255)
#  name       :text
#  created_at :datetime
#  updated_at :datetime
#  short_name :string(255)
#

class Operator < ActiveRecord::Base
  has_many :route_operators, :dependent => :destroy
  has_many :routes, :through => :route_operators, :uniq => true
  validates_presence_of :name
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$"), 
                              :if => Proc.new { |operator| !operator.email.blank? }
  accepts_nested_attributes_for :route_operators,  :reject_if => :route_operator_invalid
  has_paper_trail
  cattr_reader :per_page
  @@per_page = 20
  
  def route_operator_invalid(attributes)
    attributes['_add'] != "1"
  end
  
end
