class UserSession < Authlogic::Session::Base

  attr_accessor :login_by_password
  validate :check_password_confirmed

  # login a user without validating them - to be used in the context of confirmation tokens
  def self.login_by_confirmation(user)
    if user && user.suspended?
      session = nil
    else
      session = UserSession.new(user, remember_me=false)
      session.httponly = true
      session.save
      session
    end
  end
  
  # set a flag that indicates that the user is trying to log in with a password
  # (rather than by a confirmation token or external auth). If they are, we need 
  # to check that the password has been previously confirmed - so a new user can't 
  # create an account and log straight into it before they confirm it.
  def credentials=(value)
    super
    values = value.is_a?(Array) ? value : [value]
    case values.first
    when Hash
      self.login_by_password = values.first.with_indifferent_access[:login_by_password] if values.first.with_indifferent_access.key?(:login_by_password)
    else
      self.login_by_password = false
    end
  end
  
  
  private
  
  def check_password_confirmed
    if self.login_by_password == true && attempted_record
      errors.add(:base, ActiveRecord::Error.new(attempted_record, :password, :not_confirmed).to_s) unless attempted_record.confirmed_password?
    end
  end


end