# == Schema Information
# Schema version: 20100408120352
#
# Table name: problems
#
#  id          :integer         not null, primary key
#  subject     :text
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#  reporter_id :integer
#

class Problem < ActiveRecord::Base
  validates_presence_of :subject
  validates_presence_of :description
  has_one :reporter, :class_name => 'User'
  accepts_nested_attributes_for :reporter
end
