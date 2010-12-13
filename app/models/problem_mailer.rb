class ProblemMailer < ApplicationMailer

  cattr_accessor :sent_count, :dryrun
  
  def problem_confirmation(recipient, problem, token)
   recipients recipient.name_and_email
   from contact_from_name_and_email
   subject "[FixMyTransport] Your transport problem"
   body :problem => problem, :recipient => recipient, :link => main_url(confirm_path(:email_token => token))
  end  
  
  def comment_confirmation(recipient, comment, token)
    recipients recipient.name_and_email
    from contact_from_name_and_email
    subject "[FixMyTransport] Your transport update"
    body :comment => comment, :recipient => recipient, :link => main_url(confirm_comment_path(:email_token => token))
  end
  
  def feedback(email_params)
    recipients contact_from_name_and_email
    from email_params[:name] + " <" + email_params[:email] + ">"
    subject "[FixMyTransport] " << email_params[:subject]
    body :message => email_params[:message], :name => email_params[:name]
  end
  
  def report(problem, recipient, recipient_models, missing_recipient_models=[])
    recipient_email = ProblemMailer.get_recipient_email(recipient, problem)
    recipients recipient_email
    from problem.reply_name_and_email
    subject "Problem Report: #{problem.subject}" 
    campaign_link = problem.campaign ? main_url(campaign_path(problem.campaign)) : nil
    body({ :problem => problem, 
           :problem_link => main_url(problem_path(problem)), 
           :campaign_link => campaign_link,
           :feedback_link => main_url(feedback_path), 
           :recipient_models => recipient_models, 
           :recipient => recipient,
           :missing_recipient_models => missing_recipient_models })
  end
  
  def self.send_report(problem, recipients, missing_recipients=[])
    recipients.each do |recipient|
      if self.dryrun
        STDERR.puts("Would send the following:")
        mail = create_report(problem, recipient, recipients, missing_recipients)
        STDERR.puts(mail)
      else
        deliver_report(problem, recipient, recipients, missing_recipients)
        problem.update_attribute(:sent_at, Time.now)
        SentEmail.create!(:recipient => self.recipient_model(recipient, problem), 
                          :problem => problem)
      end
      self.sent_count += 1
    end
  end
  
  def self.check_for_council_change(problem)
    if problem.councils_responsible? 
      if problem.location.council_info != problem.council_info
        STDERR.puts "Councils changed for problem #{problem.id}. Was #{problem.council_info}, now #{problem.location.council_info}"
      end
    end
  end
  
  def self.get_recipient_email(recipient, problem)
    # on a staging site, don't send live emails
    if MySociety::Config.getbool('STAGING_SITE', true)
      return MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    else
      return self.recipient_model(recipient, problem).email
    end
  end
  
  def self.recipient_model(recipient, problem)
    if recipient.is_a?(Council)
      return recipient.contact_for_category(problem.category)
    else
      return recipient
    end
  end
  
  def self.send_reports(dryrun=false)
    self.dryrun = dryrun
    
    # make sure the mail confs are up to date
    Campaign.sync_mail_confs
    
    missing_emails = { :council => {},
                       :passenger_transport_executive => {},
                       :operator => {} }
    self.sent_count = 0
    Problem.sendable.each do |problem|

      # if campaign mail, wait until the campaign has a subdomain
      next if problem.campaign and !problem.campaign.subdomain
      
      check_for_council_change(problem)
      
      if !problem.emailable_organizations.empty?
        send_report(problem, problem.emailable_organizations, problem.unemailable_organizations)
      end
      
      problem.unemailable_organizations.each do |organization|
        missing_emails[organization.class.to_s.tableize.singularize.to_sym][organization.id] = organization
      end
      
    end
    
    if sent_count > 0
      STDERR.puts "Sent #{sent_count} reports"
    end
    
    if missing_emails[:operator].size > 0
      STDERR.puts "Operator emails that need to be found:"
      missing_emails[:operator].each{ |operator_id, operator| STDERR.puts operator.name }
    end
  
    if missing_emails[:passenger_transport_executive].size > 0
      STDERR.puts "PTE emails that need to be found:"
      missing_emails[:passenger_transport_executive].each{ |pte_id, pte| STDERR.puts pte.name } 
    end
  
    if missing_emails[:council].size > 0
      STDERR.puts "Council emails that need to be found:"
      missing_emails[:council].each{ |council_id, council| STDERR.puts council.name }
    end
  end
  
end
