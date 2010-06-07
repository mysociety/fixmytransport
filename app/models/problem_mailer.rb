class ProblemMailer < ActionMailer::Base
  
  def story_confirmation(recipient, problem, token)
   recipients recipient.email
   from       MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
   subject    "Your transport story"
   body :story => problem, :recipient => recipient, :link => confirm_url(:email_token => token)
  end  

end
