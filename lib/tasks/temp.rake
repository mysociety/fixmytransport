namespace :temp do
  desc 'Create sent email models for sent problem reports'
  task :backfill_problem_report_sent_emails => :environment do 
    Problem.confirmed.find_each do |problem|
      if problem.sent_at or RAILS_ENV == 'development'
        puts "problem id #{problem.id}"
        if problem.sent_emails.empty?
          problem.emailable_organizations.each do |organization|
            recipient = nil
            if organization.is_a?(Council)
              recipient = organization.contact_for_category(problem.category)
            else
              recipient = organization 
            end
            puts "creating sent email to #{recipient.name}"
            SentEmail.create!(:problem => problem, 
                              :recipient => recipient, 
                              :created_at => problem.sent_at)
          end
        end
      end
    end
  end 
end