# == Schema Information
# Schema version: 20100707152350
#
# Table name: users
#
#  id                :integer         not null, primary key
#  name              :string(255)
#  email             :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#  wants_fmt_updates :boolean
#

class User < ActiveRecord::Base
  validates_presence_of :email
  validates_presence_of :name, :if => :name_required
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  validates_uniqueness_of :email
  attr_accessor :name_required
  attr_accessible :name, :email, :wants_fmt_updates, :public, :name_required
  has_many :assignments
  
end
