class UserMailer < ApplicationMailer

  def password_reset_instructions(user)  
    subject "[FixMyTransport] Password reset instructions"  
    from contact_from_name_and_email
    recipients user.email  
    body :edit_password_reset_url => main_url(edit_password_reset_path(user.perishable_token))
  end

end