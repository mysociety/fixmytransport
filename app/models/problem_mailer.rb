class ProblemMailer < ApplicationMailer

  cattr_accessor :sent_count, :dryrun
  include ApplicationHelper

  def problem_confirmation(recipient, problem, token)
   recipients recipient.name_and_email
   from contact_from_name_and_email
   subject problem_confirmation_subject
   body :problem => problem, :recipient => recipient, :link => main_url(confirm_problem_path(:email_token => token))
  end

  def feedback(email_params, location=nil, operator=nil)
    recipients contact_from_name_and_email
    from email_params[:name] + " <" + email_params[:email] + ">"
    subject I18n.translate('mailers.app_subject_prefix') << email_params[:subject]
    body_params = { :message => email_params[:message],
                    :name => email_params[:name],
                    :uri => email_params[:feedback_on_uri] }
    if location
      body_params[:location] = location
      body_params[:location_url] = main_url(location_path(location))
    end
    if operator
      body_params[:operator] = operator
      body_params[:operator_url] = main_url(operator_path(operator))
    end
    body(body_params)
  end

  def report(problem, recipient, recipient_models, missing_recipient_models=[])
    recipient_email = ProblemMailer.get_recipient_email(recipient, problem)
    recipients recipient_email
    from problem.reply_name_and_email
    subject I18n.translate('mailers.problem_report_subject', :subject => problem.subject)
    campaign_link = problem.campaign ? main_url(campaign_path(problem.campaign)) : nil
    body({ :problem => problem,
           :problem_link => main_url(problem_path(problem)),
           :campaign_link => campaign_link,
           :feedback_link => main_url(feedback_path),
           :recipient_models => recipient_models,
           :recipient => recipient,
           :missing_recipient_models => missing_recipient_models })
  end

  def comment(recipient, comment, subscription)
    recipients recipient.name_and_email
    from contact_from_name_and_email
    problem = comment.commented
    subject I18n.translate('mailers.comment_subject', :title => problem.subject)
    body_hash = { :recipient => recipient,
                  :comment => comment,
                  :link => main_url(problem_path(problem)),
                  :unsubscribe_link => main_url(confirm_unsubscribe_path(:email_token => subscription.token)) }
    body(body_hash)
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
      return recipient.contact_for_category_and_location(problem.category, problem.location)
    elsif recipient.is_a?(Operator)
      return recipient.contact_for_category_and_location(problem.category, problem.location)
    elsif recipient.is_a?(PassengerTransportExecutive)
      return recipient.contact_for_category_and_location(problem.category, problem.location)
    else
      raise "Unknown recipient type: #{recipient.class.to_s}"
    end
  end

  def self.send_reports(dryrun=false, verbose=false)
    self.dryrun = dryrun

    missing_emails = { :council => {},
                       :passenger_transport_executive => {},
                       :operator => {} }
    self.sent_count = 0
    Problem.sendable.each do |problem|

      # if campaign mail, wait until the campaign has a title
      next if problem.campaign and problem.campaign.title.blank?

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

    if verbose
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

      unsendable_problems = Problem.unsendable
      if unsendable_problems.size > 0
        STDERR.puts "Organisations need to be found for the following problem locations:"
        unsendable_problems.each do |problem|
          location = problem.location_type.constantize.find(problem.location_id)
          STDERR.puts "Problem #{problem.id}: #{location.class} '#{location.name}' (id #{location.id})"
        end
      end
    end

  end

  def self.send_comment(comment, problem)
    sent_emails = SentEmail.find(:all, :conditions => ['comment_id = ?', comment])
    sent_recipients = sent_emails.map{ |sent_email| sent_email.recipient }
    subscriptions = problem.subscriptions
    subscribers = subscriptions.map{ |subscription| [subscription, subscription.user] }
    subscribers = subscribers.select{ |subscription, subscriber| ! sent_recipients.include?(subscriber) }
    subscribers.each do |subscription, subscriber|
      next if subscriber == comment.user
      if self.dryrun
        STDERR.puts("Would send the following:")
        mail = create_comment(subscriber, comment, subscription)
        STDERR.puts(mail)
      else
        deliver_comment(subscriber, comment, subscription)
        SentEmail.create!(:recipient => subscriber,
                          :problem => problem,
                          :comment => comment)
      end
    end
    if ! self.dryrun
      comment.update_attribute(:sent_at, Time.now)
    end
  end

  def self.send_comments(dryrun=false)
    self.dryrun = dryrun
    Comment.visible.unsent.find(:all, :conditions => ["commented_type = 'Problem'"]).each do |problem_comment|
      send_comment(problem_comment, problem_comment.commented)
    end
  end

end
