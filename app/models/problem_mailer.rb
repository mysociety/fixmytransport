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
  
  def report(problem, recipient_models)
    recipients recipient_models.map{ |recipient| recipient.email } + [MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')]
    from problem.reporter.email
    subject "Problem Report: #{problem.subject}" 
    body({ :problem => problem, 
           :problem_link => main_url(problem_path(problem)), 
           :feedback_link => main_url(feedback_path), 
           :recipient_models => recipient_models })
  end
  
  def self.send_reports
    missing_operator_emails = {}
    missing_pte_emails = {}
    missing_council_emails = {}
    sent_count = 0
    problems = Problem.sendable
    problems.each do |problem|
      if problem.operator
        if problem.operator.email.blank? 
          missing_operator_emails[problem.operator.id] = problem.operator
        else
          deliver_report(problem, [problem.operator])
          problem.update_attribute(:sent_at, Time.now)
          sent_count += 1
        end
      elsif problem.passenger_transport_executive
        if problem.passenger_transport_executive.email.blank?
          missing_pte_emails[problem.passenger_transport_executive.id] = problem.passenger_transport_executive
        else
          deliver_report(problem, [problem.passenger_transport_executive])
          problem.update_attribute(:sent_at, Time.now)
          sent_count += 1
        end
      elsif problem.councils
        emailable_councils, unemailable_councils = problem.councils.split('|')
        emailable_council_ids = emailable_councils.split(',').map{ |id| id.to_i }
        unemailable_council_ids = unemailable_councils.split(',').map{ |id| id.to_i }
        council_ids = unemailable_council_ids + emailable_council_ids
        council_data = MySociety::MaPit.call('areas', council_ids)
        councils = {}
        council_data.each do |council_id, council_info|
          councils[council_id] = Council.from_hash(council_info)
        end
        if !emailable_council_ids.empty?
          deliver_report(problem, emailable_council_ids.map{ |council_id| councils[council_id] })
        end
        unemailable_council_ids.each do |unemailable_council_id|
          missing_council_emails[unemailable_council_id] = councils[unemailable_council_id]
        end
      end
    end
    STDERR.puts "Sent #{sent_count} reports"
    
    STDERR.puts "Operator emails that need to be found:"
    missing_operator_emails.each{ |operator_id, operator| STDERR.puts operator.name }
    
    STDERR.puts "PTE emails that need to be found:"
    missing_pte_emails.each{ |pte_id, pte| STDERR.puts pte.name } 
   
    STDERR.puts "Council emails that need to be found:"
    missing_council_emails.each{ |council_id, council| STDERR.puts council.name }
  end
  
end
