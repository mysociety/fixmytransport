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
require 'open-uri'
require 'net/http'
require 'uri'

class User < ActiveRecord::Base
  validates_presence_of :email
  validates_presence_of :name
  validates_format_of :email, :with => Regexp.new("^#{MySociety::Validate.email_match_regexp}\$")
  validate :validate_real_name
  validate :password_not_admin_password
  validates_uniqueness_of :email, :case_sensitive => false, :unless => :skip_email_uniqueness_validation
  # Do not allow these attributes to be set by mass assignment
  attr_protected :password, :password_confirmation, :is_expert, :is_suspended,
                 :can_admin_locations, :can_admin_users, :can_admin_issues, :can_admin_organizations,
                 :is_hidden
  has_many :assignments
  has_many :campaign_supporters, :foreign_key => :supporter_id
  has_many :campaigns, :through => :campaign_supporters
  has_many :problems, :foreign_key => :reporter_id
  has_many :initiated_campaigns, :foreign_key => :initiator_id, :class_name => 'Campaign'
  has_many :sent_emails, :as => :recipient
  has_many :access_tokens
  has_many :subscriptions
  has_many :comments
  has_many :questionnaires

  # a one-to-one association conferring admin credentials on the user
  has_one :admin_user
  before_validation :download_remote_profile_photo, :if => :profile_photo_url_provided?

  has_attached_file :profile_photo,
                    :path => "#{MySociety::Config.get('FILE_DIRECTORY', ':rails_root/public/system')}/paperclip/:class/:attachment/:id/:style/:filename",
                    :url => "#{MySociety::Config.get('PAPERCLIP_URL_BASE', '/system/paperclip')}/:class/:attachment/:id/:style/:filename",
                    :default_url => "/images/paperclip_defaults/:class/:attachment/missing_:style.png",
                    :styles => { :large_thumb => "70x70#",
                                 :small_thumb => "40x40#",
                                 :medium_thumb => "46x46#" }


  before_post_process :autorotate_paperclip_image

  def autorotate_paperclip_image
    uploaded_filename = profile_photo.queued_for_write[:original].path
    # Ignore return values form autorotate_image - if it's not a JPEG
    # or reorientation fails, the original file is left untouched:
    # Note that if the jhead package on which autorotate_image depends
    # is not installed, the exception raised, although caught by the function,
    # will cause the database connection in the save transaction to be lost.
    autorotate_image(uploaded_filename)
    true
  end

  attr_accessor :ignore_blank_passwords,
                :skip_email_uniqueness_validation,
                :profile_photo_url,
                :error_on_bad_profile_photo_url,
                :force_new_record_validation,
                :force_password_validation

  has_friendly_id :name, :use_slug => true, :allow_nil => true

  named_scope :registered, :conditions => { :registered => true }

  acts_as_authentic do |c|

    # don't reset perishable tokens automatically
    c.disable_perishable_token_maintenance = true

    # moving from SHA512 to BCrypt - remove when done
    c.crypto_provider = Authlogic::CryptoProviders::BCrypt
    c.transition_from_crypto_providers = Authlogic::CryptoProviders::Sha512

    # we validate the email with activerecord validation above
    c.validate_email_field = false
    c.merge_validates_confirmation_of_password_field_options({:unless => :password_not_required,
                                                              :message => I18n.translate('accounts.new.password_match_error')})
    password_min_length = 5
    c.merge_validates_length_of_password_field_options({:unless => :password_not_required,
                                                        :minimum => password_min_length,
                                                        :message => I18n.translate('accounts.new.password_length_error',
                                                        :length => password_min_length)})
  end

  def password_not_required
    if (force_new_record_validation == true) || (force_password_validation == true)
      return false
    end
    unregistered? or !access_tokens.empty?
  end

  # If someone with admin privileges tries to set their main password to their admin password,
  # reset their admin password
  def password_not_admin_password
    if password_not_required or !self.admin_user
      return true
    else
      if !self.admin_user.valid_password?(self.password)
        return true
      else
        # Reset the admin password - no longer secure
        # N.B. if we raise a validation error here, the admin account password change
        # gets rolled back along with the account change.
        self.admin_user.reset_password!
        return true
      end
    end
  end

  def validate_real_name
    if force_new_record_validation == true || new_record?
      if /\ba\s*n+on+((y|o)mo?u?s)?(ly)?\b/i.match(name) || ! /\S\s\S/.match(name) || name.size < 5
        self.errors.add(:name, ActiveRecord::Error.new(self, :name, :not_real, :link => "<a href='/about#names' target='_blank'>policy on names</a>").to_s.html_safe)
      end
    end
   end

  # object level attribute overrides the config level
  # attribute
  def ignore_blank_passwords?
    ignore_blank_passwords.nil? ? super : (ignore_blank_passwords == true)
  end

  def unregistered?
    !registered
  end

  def suspended?
    is_suspended
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

  def mark_seen(issue)
    if issue.is_a?(Campaign)
      if current_supporter = self.campaign_supporters.confirmed.detect{ |supporter| supporter.campaign == issue }
        if current_supporter.new_supporter?
          current_supporter.new_supporter = false
          current_supporter.save
        end
      end
      if new_initiator?(issue)
        issue.update_attribute('initiator_seen', true)
      end
    elsif issue.is_a?(Problem)
      if new_reporter?(issue)
        issue.update_attribute('reporter_seen', true)
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

  def new_initiator?(campaign)
    if campaign.initiator == self && campaign.initiator_seen? == false
      return true
    else
      return false
    end
  end

  def new_reporter?(problem)
    if problem.reporter == self && problem.reporter_seen? == false
      return true
    else
      return false
    end
  end

  def answered_ever_reported?
    self.questionnaires.find(:first, :conditions => ['ever_reported is not NULL']) != nil
  end

  def download_remote_profile_photo
    self.profile_photo = do_download_remote_profile_photo
    self.profile_photo_remote_url = profile_photo_url
  end

  def do_download_remote_profile_photo
    begin
       io = open(URI.parse(profile_photo_url))
       def io.original_filename; base_uri.path.split('/').last; end
       io.original_filename.blank? ? nil : io
     rescue
       if self.error_on_bad_profile_photo_url
         raise
       end
     end
  end

  def profile_photo_url_provided?
    !self.profile_photo_url.blank?
  end

  def subscribed_to?(target)
    !self.subscriptions.find(:first, :conditions => ['target_id = ? and target_type = ? and confirmed_at is not null',
                                                      target.id, target.class.to_s]).nil?
  end

  def is_admin?
    !admin_user.nil?
  end

  def can_admin?(admin_right)
    return false unless self.is_admin?
    return false unless self.send("can_admin_#{admin_right}?") == true
    return true
  end

  def self.name_or_email_or_id_conditions(query)
    query_clauses = []
    query_params = []
    if ! query.blank?
      query = query.downcase
      query_clause = "(LOWER(name) LIKE ?
                      OR LOWER(name) LIKE ?
                      OR LOWER(email) LIKE ?
                      OR LOWER(email) LIKE ?"
      query_params = [ "#{query}%", "%#{query}%",
                       "#{query}%", "%#{query}%"]
      # numeric?
      if query.to_i.to_s == query
        query_clause += " OR id = ?"
        query_params << query.to_i
      end
      query_clause += ")"
      query_clauses << query_clause
    end
    conditions = [query_clauses.join(" AND ")] + query_params
  end

  # class methods

  def self.get_facebook_data(access_token)
    graph_api_url = MySociety::Config.get('FACEBOOK_GRAPH_API_URL', '')
    if graph_api_url
      query_string = "access_token=#{CGI::escape(access_token)}&fields=name,email,picture&type=large"
      contents = open("#{graph_api_url}/me?#{query_string}").read
      facebook_data = JSON.parse(contents)
    end
  end

  def self.handle_external_auth_token(access_token, source, remember_me)
    case source
    when 'facebook'
      success = false
      facebook_data = self.get_facebook_data(access_token)
      fb_id = facebook_data['id']
      AccessToken.transaction do
        existing_access_token = AccessToken.find(:first, :conditions => ['key = ? and token_type = ?', fb_id, source])
        if existing_access_token
          user = existing_access_token.user
          success = true
        else
          name = facebook_data['name']
          email = facebook_data['email']
          if email.blank?
            raise "Error: no email in Facebook data: #{facebook_data.inspect}, access token: #{access_token}"
          end
          user = User.find(:first, :conditions => ['lower(email) = ?', email.downcase])
          if not user
            user = User.new({:name => name, :email => email})
          end
          user.registered = true
          # don't replace an existing uploaded photo
          if ! user.profile_photo?
            # discard the profile photo if it's just the default
            if facebook_data['picture']
              if ! facebook_data['picture']['data']['is_silhouette']
                user.profile_photo_url = facebook_data['picture']['data']['url']
                user.error_on_bad_profile_photo_url = false
              end
            end
          end
          user.access_tokens.build({:user_id => user.id,
                                    :token_type => 'facebook',
                                    :key => fb_id,
                                    :token => access_token})
          success = user.save_without_session_maintenance
        end
        if success
          if user.suspended?
            raise I18n.translate('shared.suspended.forbidden')
          else
            session = UserSession.new(user, remember_me=remember_me)
            session.httponly = true
            session.save
            session
          end
        else
          raise "Error in external auth. Facebook data #{facebook_data.inspect} #{user.errors.full_messages.join(",")}"
        end
      end
    end
  end


  def self.get_facebook_profile_picture_url(access_token)

    if graph_api_url

      contents = open("#{graph_api_url}/#{access_token.key}?#{query_string}").read
      facebook_data = JSON.parse(contents)
      if facebook_data['picture']
        return facebook_data['picture']
      end
    end
    return nil
  end

  def self.get_facebook_app_access_token(http_session, verbose)
    facebook_app_id = MySociety::Config.get('FACEBOOK_APP_ID', '')
    facebook_app_secret = MySociety::Config.get('FACEBOOK_APP_SECRET', '')
    if ! facebook_app_id or ! facebook_app_secret
      raise "Missing Facebook app credentials"
    end
    auth_params = { :client_id => facebook_app_id,
                    :client_secret => facebook_app_secret,
                    :grant_type => 'client_credentials' }
    app_auth_request = Net::HTTP::Get.new("/oauth/access_token?#{auth_params.to_param}")
    app_auth_response = http_session.request(app_auth_request)
    case app_auth_response
    when Net::HTTPSuccess
      response_body = app_auth_response.body
      field, value = response_body.split("=")
      if field != 'access_token'
        raise "Unexpected response from Facebook app authentication: #{field}=#{value}"
      end
      access_token = value
      puts "Got app access token: #{access_token}" if verbose
    else
      app_auth_response.error!
    end
    return access_token
  end

  def self.get_facebook_batch_api_data(http_session, fb_query_set, access_token, verbose, is_retry=false)
    retry_delay = 10
    profile_data_request = Net::HTTP::Post.new('/')
    profile_data_request.body = "access_token=#{access_token}&batch=#{CGI.escape(fb_query_set.to_json)}"
    puts "Asking for picture data on #{fb_query_set.size} users" if verbose
    profile_picture_response = http_session.request(profile_data_request)
    case profile_picture_response
    when Net::HTTPSuccess
      response_body = profile_picture_response.body
      profile_picture_data = JSON.load(response_body)
      puts "Got picture data" if verbose
    else
      if ! is_retry
        puts "Got error, retrying in #{retry_delay} seconds" if verbose
        sleep(retry_delay)
        return self.get_facebook_batch_api_data(http_session, fb_query_set, access_token, verbose, is_retry=true)
      else
        profile_picture_response.error!
      end
    end
    return profile_picture_data
  end

  def self.update_remote_profile_photos(verbose=false)
    graph_api_url = MySociety::Config.get('FACEBOOK_GRAPH_API_URL', '')
    facebook_batch_api_limit = 20
    if graph_api_url

      facebook_queries = []

      # get a list of fb keys that we want to check profile pictures for
      AccessToken.find_each(:conditions => ['token_type = ?', 'facebook'], :include => :user) do |access_token|
        user = access_token.user
        if ! user.profile_photo? or !user.profile_photo_remote_url.blank?
          query_string = "fields=id,picture&type=large"
          facebook_queries << {:method => 'GET', :relative_url => "#{access_token.key}?#{query_string}"}
        end
      end

      # Set up an SSL session
      graph_uri = URI.parse(graph_api_url)
      http = Net::HTTP.new(graph_uri.host, graph_uri.port)
      http.use_ssl = true
      http.ca_path = MySociety::Config.get("SSL_CA_PATH", "/etc/ssl/certs/")
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER

      # get an app access token
      access_token = self.get_facebook_app_access_token(http, verbose)

      # get the profile data
      facebook_queries.each_slice(facebook_batch_api_limit) do |fb_query_set|
        profile_picture_data = self.get_facebook_batch_api_data(http, fb_query_set, access_token, verbose)
        profile_picture_data.each do |picture_response|
          self.set_profile_remote_photo(picture_response['body'], verbose) if picture_response
        end
      end
    end
  end

  def self.set_profile_remote_photo(json_response, verbose)
    picture_data = JSON.load(json_response)
    if picture_data.has_key?('error')
      puts "Error: #{picture_data['error'].inspect}"
      return
    end
    picture_url =  picture_data['picture']['data']['url']
    picture_static = picture_data['picture']['data']['is_silhouette']
    id = picture_data['id']
    puts "FB key: #{id}, url #{picture_url}" if verbose
    token = AccessToken.find(:first, :conditions => ['key = ? and token_type = ?', id, 'facebook'])
    if !token
      puts "No token for returned key #{id}" if verbose
    else
      user = token.user
      puts "Looking at picture URL for user #{user.id}" if verbose
      if picture_url == user.profile_photo_remote_url
        puts "Remote profile picture URL for user #{user.id} is same as current" if verbose
      else
        if picture_static
          puts "Remote profile picture URL for user #{user.id} is static #{picture_url}" if verbose
        else
          puts "Setting remote profile picture URL for user to #{picture_url}" if verbose
          self.update_remote_profile_photo(user, picture_url)
        end
      end
    end
  end

  def self.facebook_static_profile_picture?(url)
    if /static/ =~ url
      return true
    else
      return false
    end
  end

  def self.update_remote_profile_photo(user, photo_url)
    user.profile_photo_url = photo_url
    user.error_on_bad_profile_photo_url = true
    user.save_without_session_maintenance
  end

end

