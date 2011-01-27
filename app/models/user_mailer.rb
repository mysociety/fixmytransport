class UserMailer < ApplicationMailer

  def password_reset_instructions(user)  
    subject "[FixMyTransport] Password reset instructions"  
    from contact_from_name_and_email
    recipients user.email  
    body :edit_password_reset_url => main_url(edit_password_reset_path(user.perishable_token)), :user => user
  end

  def new_account_confirmation(user)
    subject "[FixMyTransport] Confirm your account"
    from contact_from_name_and_email
    recipients user.email
    body :account_confirmation_url => main_url(confirm_account_path(user.perishable_token)), :user => user
  end
  
  def already_registered(user)
    subject "[FixMyTransport] Confirm your account"
    from contact_from_name_and_email
    recipients user.email
    body :account_confirmation_url => main_url(confirm_account_path(user.perishable_token)), :user => user   
  end
  
end