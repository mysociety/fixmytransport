# == Schema Information
# Schema version: 20100707152350
#
# Table name: feedbacks
#
#  email   :string
#  name    :string
#  subject :string
#  message :string
#

class Feedback < ActiveRecord::BaseWithoutTable
  
  column :email, :string
  column :name, :string
  column :subject, :string
  column :message, :string
  column :feedback_on_uri, :string

  validates_presence_of :email, :name, :subject, :message
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  
end
