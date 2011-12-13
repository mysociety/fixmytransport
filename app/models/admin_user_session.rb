class AdminUserSession < Authlogic::Session::Base

  login_field :email
  find_by_login_method  :find_by_login
  # don't reveal what attribute each error message is associated with
  generalize_credentials_error_messages true

end