# == Schema Information
# Schema version: 20100408173847
#
# Table name: problems
#
#  id          :integer         not null, primary key
#  subject     :text
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#  reporter_id :integer
#  stop_id     :integer
#

class Problem < ActiveRecord::Base
  validates_presence_of :subject
  validates_presence_of :description
  has_one :reporter, :class_name => 'User'
  accepts_nested_attributes_for :reporter
  belongs_to :stop
  
  def stop_attributes=(attributes)
    self.stop = Stop.find(:first, :conditions => ['common_name = ? and locality_name = ?', attributes[:common_name], attributes[:locality_name]])
  end
  
end
