class CampaignMailer < ApplicationMailer

  cattr_accessor :sent_count, :dryrun

  def new_message(recipient, incoming_message, campaign)
    recipients recipient.name_and_email
    from contact_from_name_and_email
    subject I18n.translate('mailers.new_message_subject', :title => campaign.title)
    url = main_url(campaign_incoming_message_path(campaign,incoming_message))
    body :campaign => campaign, :recipient => recipient, :link => url
  end

  def update(recipient, campaign, subscription, update)
    recipients recipient.name_and_email
    from contact_from_name_and_email
    subject I18n.translate('mailers.update_subject', :title => campaign.title)
    body_hash = { :campaign => campaign,
                  :recipient => recipient,
                  :update => update,
                  :link => main_url(campaign_path(campaign)) }
    if subscription
      body_hash[:unsubscribe_link] = main_url(confirm_unsubscribe_path(:email_token => subscription.token))
    end
    body(body_hash)
  end

  def comment(recipient, campaign, subscription, comment)
    recipients recipient.name_and_email
    from contact_from_name_and_email
    subject I18n.translate('mailers.comment_subject', :title => campaign.title)
    body_hash = { :campaign => campaign, 
                  :recipient => recipient, 
                  :comment => comment, 
                  :link => main_url(campaign_path(campaign)) }
    if subscription 
      body_hash[:unsubscribe_link] = main_url(confirm_leave_path(:email_token => subscription.token))
    end
    body(body_hash)
  end

  def expert_advice_request(campaign, advice_request)
    recipients experts_from_name_and_email
    from contact_from_name_and_email
    subject I18n.translate('mailers.advice_request_subject', :title => campaign.title)
    body({ :campaign => campaign,
           :advice_request => advice_request,
           :assignment_link => main_url(new_campaign_assignment_path(campaign)),
           :advice_link => main_url(campaign_path(campaign)) })
  end

  def advice_request(recipient, campaign, supporter, advice_request)
    recipients recipient.name_and_email
    from contact_from_name_and_email
    subject I18n.translate('mailers.advice_request_subject', :title => campaign.title)
    body_hash = { :campaign => campaign,
                  :recipient => recipient,
                  :advice_request => advice_request,
                  :link => main_url(campaign_path(campaign)) }
    if supporter
      body_hash[:unsubscribe_link] = main_url(confirm_leave_path(:email_token => supporter.token))
    end
    body(body_hash)
  end

  def write_to_other_assignment(assignment, subject)
    recipients assignment.user.name_and_email
    from experts_from_name_and_email(assignment.creator)
    subject subject
    body({ :assignment => assignment,
           :link => main_url(new_campaign_outgoing_message_path(assignment.campaign, :assignment_id => assignment))})
  end

  def outgoing_message(outgoing_message)
    recipients outgoing_message.recipient_email
    from outgoing_message.reply_name_and_email
    subject outgoing_message.subject
    body({ :outgoing_message => outgoing_message,
           :privacy_link => main_url(about_path(:anchor => "privacy")),
           :feedback_link => main_url(feedback_path) })
  end


  def completed_assignment(campaign, assignment)
    recipients contact_from_name_and_email
    from contact_from_name_and_email
    subject I18n.translate('mailers.completed_assignment_subject', :title => campaign.title)
    body({ :assignment => assignment,
           :campaign => campaign })
  end

  def campaigns_matching_email(email)
    campaigns = []
    addresses = (email.to || []) + (email.cc || [])
    addresses.each do |address|
      campaign = Campaign.find_by_campaign_email(address)
      if campaign
        recipient = campaign.get_recipient(address)
        campaigns << [campaign, recipient]
      end
    end
    return campaigns
  end

  def receive(email, raw_email)
    campaigns = campaigns_matching_email(email)
    if campaigns.empty? 
      # no matching campaigns
      IncomingMessage.create_from_tmail(email, raw_email, nil)
    else
      campaigns.each do |campaign, recipient|
        incoming_message = IncomingMessage.create_from_tmail(email, raw_email, campaign)
        CampaignMailer.deliver_new_message(recipient, incoming_message, campaign)
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

  def self.send_update(update_or_comment, campaign)
    if update_or_comment.is_a?(CampaignUpdate)
      sent_emails = SentEmail.find(:all, :conditions => ['campaign_update_id = ?', update_or_comment])
      if update_or_comment.is_advice_request?
        if self.dryrun
          STDERR.puts("Would send the following:")
          mail = create_expert_advice_request(campaign, update_or_comment)
          STDERR.puts(mail)
        else
          deliver_expert_advice_request(campaign, update_or_comment)
        end
      end
    else
      sent_emails = SentEmail.find(:all, :conditions => ['comment_id = ?', update_or_comment])
    end
    
    sent_recipients = sent_emails.map{ |sent_email| sent_email.recipient }
    campaign_subscriptions = campaign.subscriptions.confirmed    
    recipients = campaign_subscriptions.map{ |campaign_subscription| [campaign_subscription, 
                                                                      campaign_subscription.user] }
    if update_or_comment.is_a?(Comment)
      recipients << [nil, campaign.initiator]
    end
    recipients = recipients.select{ |supporter, recipient| !sent_recipients.include? recipient }
    recipients.each do |subscription, recipient|
      # don't send an email to the person who created the update or comment
      next if recipient == update_or_comment.user
      
      if self.dryrun
        STDERR.puts("Would send the following:")
        if update_or_comment.is_a?(CampaignUpdate) && update_or_comment.is_advice_request?
          mail = create_advice_request(recipient, campaign, subscription, update_or_comment)
        elsif update_or_comment.is_a?(CampaignUpdate)
          mail = create_update(recipient, campaign, subscription, update_or_comment)
        else
          mail = create_comment(recipient, campaign, subscription, update_or_comment)
        end
        STDERR.puts(mail)
      else
        if update_or_comment.is_a?(CampaignUpdate) && update_or_comment.is_advice_request?
          deliver_advice_request(recipient, campaign, subscription, update_or_comment)
        elsif update_or_comment.is_a?(CampaignUpdate)
          deliver_update(recipient, campaign, subscription, update_or_comment)
        else
          deliver_comment(recipient, campaign, subscription, update_or_comment)
        end
        
        sent_email_attributes = { :recipient => recipient,
                                  :campaign => campaign }
        if update_or_comment.is_a?(CampaignUpdate)
          sent_email_attributes[:campaign_update] = update_or_comment
        else
          sent_email_attributes[:comment] = update_or_comment
        end
        SentEmail.create!(sent_email_attributes)
      end
    end
    if ! self.dryrun
      update_or_comment.update_attribute(:sent_at, Time.now)
    end
    self.sent_count += 1
  end

  def self.send_updates(dryrun=false)
    self.dryrun = dryrun
    self.sent_count = 0
    CampaignUpdate.sendable.each do |campaign_update|
      send_update(campaign_update, campaign_update.campaign)
    end
  end
  
  def self.send_comments(dryrun=false)
    self.dryrun = dryrun
    self.sent_count = 0
    Comment.visible.unsent.find(:all, :conditions => ["commented_type = 'Campaign'"]).each do |campaign_comment|
      send_update(campaign_comment, campaign_comment.commented)
    end
  end
  
end