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
  validates_presence_of :name
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  validates_uniqueness_of :email, :case_sensitive => false
  attr_protected :password, :password_confirmation, :is_expert
  has_many :assignments
  has_many :campaign_supporters, :foreign_key => :supporter_id
  has_many :campaigns, :through => :campaign_supporters
  has_many :problems, :foreign_key => :reporter_id
  has_many :initiated_campaigns, :foreign_key => :initiator_id, :class_name => 'Campaign'
  has_many :sent_emails, :as => :recipient
  has_many :access_tokens
  has_attached_file :profile_photo,
                    :path => "#{MySociety::Config.get('FILE_DIRECTORY', ':rails_root/public/system')}/paperclip/:class/:attachment/:id/:style/:filename",
                    :url => "#{MySociety::Config.get('PAPERCLIP_URL_BASE', '/system/paperclip')}/:class/:attachment/:id/:style/:filename",
                    :default_url => "/images/paperclip_defaults/:class/:attachment/missing_:style.png",
                    :styles => { :large_thumb => "70x70#",
                                 :small_thumb => "40x40#",
                                 :medium_thumb => "46x46#" }

  attr_accessor :ignore_blank_passwords
  has_friendly_id :name, :use_slug => true, :allow_nil => true

  named_scope :registered, :conditions => { :registered => true }

  acts_as_authentic do |c|
    # we validate the email with activerecord validation above
    c.validate_email_field = false
    c.merge_validates_confirmation_of_password_field_options({:unless => :password_not_required,
                                                              :message => I18n.translate(:password_match_error)})
    password_min_length = 5
    c.merge_validates_length_of_password_field_options({:unless => :password_not_required,
                                                        :minimum => password_min_length,
                                                        :message => I18n.translate(:password_length_error,
                                                                                   :length => password_min_length)})
  end

  # object level attribute overrides the config level
  # attribute
  def ignore_blank_passwords?
    ignore_blank_passwords.nil? ? super : (ignore_blank_passwords == true)
  end

  def password_not_required
    unregistered? or !access_tokens.empty?
  end
  
  def unregistered?
    !registered
  end

  def first_name
    name.split(' ').first
  end

  def name_and_email
    FixMyTransport::Email::Address.address_from_name_and_email(self.name, self.email).to_s
  end

  def campaign_name_and_email_address(campaign)
    FixMyTransport::Email::Address.address_from_name_and_email(self.name, campaign.email_address).to_s
  end

  def save_if_new
    if new_record?
      save_without_session_maintenance
    end
    return true
  end
  
  def deliver_password_reset_instructions!
    reset_perishable_token!
    UserMailer.deliver_password_reset_instructions(self)
  end
  
  def mark_seen(campaign)
    if current_supporter = self.campaign_supporters.confirmed.detect{ |supporter| supporter.campaign == campaign }
      if current_supporter.new_supporter?
        current_supporter.new_supporter = false
        current_supporter.save
      end
    end
  end
  
  def supporter_or_initiator(campaign)
    return (self == campaign.initiator || campaign.supporters.include?(self))
  end
  
  def new_supporter?(campaign)
    if current_supporter = self.campaign_supporters.confirmed.detect{ |supporter| supporter.campaign == campaign }
      if current_supporter.new_supporter?
        return true
      end
    end
    return false
  end
  
  # class methods
  
  def self.get_facebook_data(access_token)
    require 'open-uri'
    contents = open("https://graph.facebook.com/me?access_token=#{CGI::escape(access_token)}").read
    facebook_data = JSON.parse(contents)
  end

  def self.handle_external_auth_token(access_token, source, remember_me)
    case source
    when 'facebook'
      facebook_data = self.get_facebook_data(access_token)
      fb_id = facebook_data['id']
      existing_access_token = AccessToken.find(:first, :conditions => ['key = ? and token_type = ?', fb_id, source])
      if existing_access_token
        user = existing_access_token.user
      else
        name = facebook_data['name']
        email = facebook_data['email']
        user = User.find(:first, :conditions => ['email = ?', email])
        if not user
          user = User.new({:name => name, :email => email})
        end   
        user.registered = true
        user.access_tokens.build({:user_id => user.id,
                                    :token_type => 'facebook',
                                    :key => fb_id,
                                    :token => access_token})
        user.save_without_session_maintenance
      end
      UserSession.create(user, remember_me=remember_me)
    end
  end
  

end

