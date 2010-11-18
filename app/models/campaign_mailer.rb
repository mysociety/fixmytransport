class CampaignMailer < ActionMailer::Base
  include MySociety::UrlMapper
  # include view helpers
  helper :application
  cattr_accessor :sent_count, :dryrun
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
  
  def update(recipient, campaign, supporter, update)
    recipients recipient.email
    from MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    subject "[FixMyTransport] Campaign update on \"#{campaign.title}\""
    body({ :campaign => campaign, 
           :recipient => recipient, 
           :update => update, 
           :link => main_url(campaign_path(campaign, :anchor => "update_#{update.id}")),
           :unsubscribe_link => main_url(confirm_leave_path(:email_token => supporter.token)) })
  end
  
  def expert_advice_request(campaign, advice_request)
    recipients MySociety::Config.get('EXPERT_EMAIL', 'contact@localhost')
    from MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    subject "[FixMyTransport] Advice request from \"#{campaign.title}\""
    body({ :campaign => campaign, 
           :advice_request => advice_request, 
           :link => main_url(campaign_path(campaign, :anchor => "update_#{advice_request.id}")) })
  end
  
  def advice_request(recipient, campaign, supporter, advice_request)
    recipients recipient.email
    from MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    subject "[FixMyTransport] Advice request from \"#{campaign.title}\""
    body({ :campaign => campaign, 
           :recipient => recipient, 
           :advice_request => advice_request, 
           :link => main_url(add_comment_campaign_url(campaign, :update_id => advice_request.id)),
           :unsubscribe_link => main_url(confirm_leave_path(:email_token => supporter.token)) })
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
  
  def self.send_update(update)
    campaign = update.campaign
    sent_emails = SentEmail.find(:all, :conditions => ['campaign_update_id = ?', update])
    sent_recipients = sent_emails.map{ |sent_email| sent_email.recipient }
    if update.is_advice_request? 
      if self.dryrun
        STDERR.puts("Would send the following:")
        mail = create_expert_advice_request(campaign, update)
        STDERR.puts(mail)
      else
        deliver_expert_advice_request(campaign, update)
      end
    end
    supporters = campaign.campaign_supporters.confirmed
    supporters = supporters.select{ |supporter| !sent_recipients.include? supporter.supporter }
    supporters.each do |supporter|
      recipient = supporter.supporter
      # don't send an email to the person who created the update
      next if recipient == update.user
      if self.dryrun
        STDERR.puts("Would send the following:")
        if update.is_advice_request? 
          mail = create_advice_request(recipient, campaign, supporter, update)
        else
          mail = create_update(recipient, campaign, supporter, update)
        end
        STDERR.puts(mail)
      else
        if update.is_advice_request? 
          deliver_advice_request(recipient, campaign, supporter, update)
        else
          deliver_update(recipient, campaign, supporter, update)
        end
        SentEmail.create!(:recipient => recipient, 
                          :campaign => campaign, 
                          :campaign_update => update)
      end
    end
    if ! self.dryrun
      update.update_attribute(:sent_at, Time.now)
    end
    self.sent_count += 1
  end
  
  def self.send_updates(dryrun=false)
    self.dryrun = dryrun
    
    self.sent_count = 0
    
    CampaignUpdate.sendable.each do |campaign_update|
      send_update(campaign_update)
    end
  end
end