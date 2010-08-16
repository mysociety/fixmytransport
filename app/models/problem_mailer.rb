class ProblemMailer < ActionMailer::Base
  include MySociety::UrlMapper
  
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
  
  def report(problem)
    recipients [problem.operator.email, MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')]
    from problem.reporter.email
    subject "Problem Report: #{problem.subject}" 
    body :problem => problem, :problem_link => main_url(problem_path(problem)), :feedback_link => main_url(feedback_path)
  end
  
  def self.send_reports
    missing_operator_emails = {}
    sent_count = 0
    problems = Problem.sendable
    problems.each do |problem|
      if problem.operator.email.blank? 
        missing_operator_emails[problem.operator.id] = problem.operator
      else
        deliver_report(problem)
        problem.update_attribute(:sent_at, Time.now)
        sent_count += 1
      end
    end
    STDERR.puts "Sent #{sent_count} reports"
    STDERR.puts "Operator emails that need to be found:"
    missing_operator_emails.each do |operator_id, operator|
      STDERR.puts "#{operator.name}"
    end
  end
  
end
