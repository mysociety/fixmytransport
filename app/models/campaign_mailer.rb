class CampaignMailer < ActionMailer::Base
  
  def campaign_confirmation(recipient, campaign, token)
   recipients recipient.email
   from       MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
   subject    "[FixMyTransport] Your transport campaign"
   body :campaign => campaign, :recipient => recipient, :link => confirm_url(:email_token => token)
  end  
  
  def feedback(email_params)
    recipients MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    from email_params[:email]
    subject "[FixMyTransport] " << email_params[:subject]
    body :message => email_params[:message], :name => email_params[:name]
  end
  
end
