class ProblemMailer < ActionMailer::Base
  
  def problem_confirmation(recipient, problem, token)
   recipients recipient.email
   from       MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
   subject    "[FixMyTransport] Your transport problem"
   body :problem => problem, :recipient => recipient, :link => confirm_url(:email_token => token)
  end  
  
  def feedback(email_params)
    recipients MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    from email_params[:email]
    subject "[FixMyTransport] " << email_params[:subject]
    body :message => email_params[:message], :name => email_params[:name]
  end
  
end
