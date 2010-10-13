class ProblemMailer < ActionMailer::Base
  include MySociety::UrlMapper
  cattr_accessor :sent_count, :dryrun
  # include view helpers
  helper :application
  url_mapper # See MySociety::UrlMapper
  
  def problem_confirmation(recipient, problem, token)
   recipients recipient.email
   from MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
   subject "[FixMyTransport] Your transport problem"
   body :problem => problem, :recipient => recipient, :link => main_url(confirm_path(:email_token => token))
  end  
  
  def update_confirmation(recipient, update, token)
    recipients recipient.email
    from MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    subject "[FixMyTransport] Your transport update"
    body :update => update, :recipient => recipient, :link => main_url(confirm_update_path(:email_token => token))
  end
  
  def feedback(email_params)
    recipients MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    from email_params[:email]
    subject "[FixMyTransport] " << email_params[:subject]
    body :message => email_params[:message], :name => email_params[:name]
  end
  
  def report(problem, recipient_models, missing_recipient_models=[])
    recipient_emails = ProblemMailer.get_report_recipients(problem)
    recipients recipient_emails + [MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')]
    from problem.reply_email
    subject "Problem Report: #{problem.subject}" 
    campaign_link = problem.campaign ? main_url(campaign_path(problem.campaign)) : nil
    body({ :problem => problem, 
           :problem_link => main_url(problem_path(problem)), 
           :campaign_link => campaign_link,
           :feedback_link => main_url(feedback_path), 
           :recipient_models => recipient_models, 
           :missing_recipient_models => missing_recipient_models })
  end
  
  def self.send_report(problem, recipients, missing_recipients=[])
    if self.dryrun
      STDERR.puts("Would send the following:")
      mail = create_report(problem, recipients, missing_recipients)
      STDERR.puts(mail)
    else
      deliver_report(problem, recipients, missing_recipients)
      problem.update_attribute(:sent_at, Time.now)
    end
    self.sent_count += 1
  end
  
  def self.check_for_council_change(problem)
    if problem.councils_responsible? 
      if problem.location.council_info != problem.council_info
        STDERR.puts "Councils changed for problem #{problem.id}. Was #{problem.council_info}, now #{problem.location.council_info}"
      end
    end
  end
  
  def self.get_report_recipients(problem)
    recipients = []
    problem.emailable_organizations.each do |emailable_organization|
      if emailable_organization.is_a?(Council)
        recipients << emailable_organization.email_for_category(problem.category)
      else
        recipients << emailable_organization.email
      end
    end
    recipients
  end
  
  def self.send_reports(dryrun=false)
    self.dryrun = dryrun
    
    # on a staging site, don't send live emails
    if MySociety::Config.getbool('STAGING_SITE', true)
      self.dryrun = true
    end
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
    
    STDERR.puts "Sent #{sent_count} reports"
    
    STDERR.puts "Operator emails that need to be found:"
    missing_emails[:operator].each{ |operator_id, operator| STDERR.puts operator.name }
    
    STDERR.puts "PTE emails that need to be found:"
    missing_emails[:passenger_transport_executive].each{ |pte_id, pte| STDERR.puts pte.name } 
   
    STDERR.puts "Council emails that need to be found:"
    missing_emails[:council].each{ |council_id, council| STDERR.puts council.name }
  end
  
end
