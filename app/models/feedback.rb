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
  column :website, :string
  column :feedback_on_uri, :string
  column :location_id
  column :location_type
  column :operator_id

  validates_presence_of :email, :name, :subject, :message
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")

  def is_spam?
    return true if ! self.website.blank?
    return false
  end

end
