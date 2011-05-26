class UserSession < Authlogic::Session::Base

  # login a user without validating them - to be used in the context of confirmation tokens
  def self.login_by_confirmation(user)
    session = UserSession.new()
    session.unauthorized_record = user
    session.remember_me = false
    session.save!
  end

end