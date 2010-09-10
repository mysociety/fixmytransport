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
  validates_presence_of :name, :unless => :unregistered?
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  validates_uniqueness_of :email
  attr_accessible :name, :email, :password, :password_confirmation
  has_many :assignments
  has_many :campaign_supporters, :foreign_key => :supporter_id
  has_many :campaigns, :through => :campaign_supporters
  
  acts_as_authentic do |c|
    # we validate the email with activerecord validation above
    c.validate_email_field = false
    c.merge_validates_confirmation_of_password_field_options({:unless => :unregistered?, 
                                                              :message => I18n.translate(:password_match_error)})
    password_min_length = 5
    c.merge_validates_length_of_password_field_options({:unless => :unregistered?,
                                                        :minimum => password_min_length,
                                                        :message => I18n.translate(:password_length_error, 
                                                                                   :length => password_min_length)})
  end 
  
  def unregistered?
    !registered
  end
  
  def save_if_new
    if new_record?
      save_without_session_maintenance
    end
    return true
  end
  
end
