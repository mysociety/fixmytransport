class Feedback < ActiveRecord::BaseWithoutTable
  
  column :email, :string
  column :name, :string
  column :subject, :string
  column :message, :string

  validates_presence_of :email, :name, :subject, :message
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  
end