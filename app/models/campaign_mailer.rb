class CampaignMailer < ActionMailer::Base
  include MySociety::UrlMapper
  # include view helpers
  helper :application
  url_mapper # See MySociety::UrlMapper
  
  def supporter_confirmation(recipient, campaign, token)
    recipients recipient.email
    from MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    subject "[FixMyTransport] Confirm that you want to join \"#{campaign.title}\""
    body :campaign => campaign, :recipient => recipient, :link => main_url(confirm_join_path(:email_token => token))
  end
  
  def receive(email, raw_email)
    campaigns = []
    addresses = (email.to || []) + (email.cc || [])
    addresses.each do |address|
      campaign = Campaign.find_by_campaign_email(address)
      campaigns << campaign if campaign
    end
    campaigns.each do |campaign|
      IncomingMessage.create_from_tmail(email, raw_email, campaign)
    end
  end  
  
  # class methods
  def self.receive(raw_email)
    logger.info "Received mail:\n #{raw_email}" unless logger.nil?
    mail = TMail::Mail.parse(raw_email)
    mail.base64_decode
    new.receive(mail, raw_email)
  end
  
end