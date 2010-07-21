class StoryMailer < ActionMailer::Base
  
  def story_confirmation(recipient, story, token)
   recipients recipient.email
   from       MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
   subject    "[Brief Encounters] Your transport story"
   body :story => story, :recipient => recipient, :link => confirm_url(:email_token => token)
  end  
  
  def feedback(email_params)
    recipients MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    from email_params[:email]
    subject "[Brief Encounters] " << email_params[:subject]
    body :message => email_params[:message], :name => email_params[:name], :uri => email_params[:feedback_on_uri]
  end
  
end
