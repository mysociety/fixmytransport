# A model to hold credentials for accessing the admin interface.
class AdminUser < ActiveRecord::Base

  validate :password_not_user_password
  belongs_to :user
  # Do not allow these attributes to be set by mass assignment
  attr_protected :password, :password_confirmation
  # require a mix of upper and lower case and number or punctuation chars
  validates_format_of :password, :with =>  /^.*(?=.*[a-z])(?=.*[A-Z])(?=.*[\d\W]).*$/,
  :message => I18n.translate('admin.password_bad_format', :length => 8)
  acts_as_authentic do |c|

    # If an admin user changes their password, maintain their session (i.e. don't force them to log back in)
    # by specifying to Authlogic that sessions with id :admin should be maintained
    c.session_ids = [:admin]

    c.crypto_provider = Authlogic::CryptoProviders::BCrypt

    c.merge_validates_confirmation_of_password_field_options({:message => I18n.translate('admin.password_match_error')})
    password_min_length = 8
    c.merge_validates_length_of_password_field_options({:minimum => password_min_length,
                                                        :message => I18n.translate('admin.password_bad_format',
                                                        :length => password_min_length)})
  end

  # Find an admin user record associated with the user whose email address we have
  # in order to check their admin credentials
  def self.find_by_login(email)
    user = User.find(:first, :conditions => ['email = ?', email])
    if user
      return user.admin_user
    else
      return nil
    end
  end

  # It should be a validation error if the admin user password is set to the same value as the
  # password of the main user account it is associated with
  def password_not_user_password
    if !self.user.valid_password?(self.password)
      return true
    else
      self.errors.add(:base, I18n.translate('admin.password_same_as_main_error'))
    end
  end

end