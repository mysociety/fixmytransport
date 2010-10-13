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
  
  def new_message(recipient, incoming_message, campaign)
    recipients recipient.email
    from MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    subject "[FixMyTransport] New message to \"#{campaign.title}\""
    body :campaign => campaign, :recipient => recipient, :link => main_url(incoming_message_path(incoming_message))
  end
  
  def receive(email, raw_email)
    addresses = (email.to || []) + (email.cc || [])
    addresses.each do |address|
      campaign = Campaign.find_by_campaign_email(address)
      if campaign
        incoming_message = IncomingMessage.create_from_tmail(email, raw_email, campaign)
        recipient = campaign.get_recipient(address)
        CampaignMailer.deliver_new_message(recipient, incoming_message, campaign)
      else
        logger.info "Undeliverable mail to #{address}"
      end
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