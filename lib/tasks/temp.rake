namespace :temp do
  
  desc 'Unset the send_questionnaire flag for campaigns and problems reported fixed by the user'
  task :unset_send_questionnaire => :environment do 
    # only initiator can mark campaign as fixed. 
    Campaign.connection.execute("UPDATE campaigns 
                                 SET send_questionnaire = 'f'
                                 WHERE status_code = #{Campaign.symbol_to_status_code[:fixed]}")

    # problems where the reporter has been the one marking them as fixed
    Problem.connection.execute("UPDATE problems 
                                SET send_questionnaire = 'f' 
                                WHERE status_code = #{Problem.symbol_to_status_code[:fixed]}
                                      AND ((SELECT max(id) 
                                           FROM comments
                                           WHERE commented_type = 'Problem'
                                           AND commented_id = problems.id
                                           AND mark_fixed = 't') = 
                                           (SELECT max(id) 
                                            FROM comments
                                            WHERE commented_type = 'Problem'
                                            AND commented_id = problems.id
                                            AND mark_fixed = 't'
                                            AND user_id = problems.reporter_id))")
  end
  
  task :send_test_questionnaires => :environment do 
    email = ENV['EMAIL']
    unless email
      puts "Requires EMAIL param to identify user"
      exit(0)
    end
    user = User.find_by_email(email)
    weeks_ago = 4
    campaign = Campaign.needing_questionnaire(weeks_ago, user).first
    problem = Problem.needing_questionnaire(weeks_ago, user).first  
    questionnaire = campaign.questionnaires.create!(:user => user, :sent_at => Time.now)
    QuestionnaireMailer.deliver_questionnaire(campaign, questionnaire, user, campaign.title)
    questionnaire = problem.questionnaires.create!(:user => user, :sent_at => Time.now)
    QuestionnaireMailer.deliver_questionnaire(problem, questionnaire, user, problem.subject)
  end
  
  task :find_custom_responsibilities => :environment do 
    Problem.visible.find_each do |problem|
      if problem.responsible_organizations.any?{ |org| !problem.location.responsible_organizations.include?(org) }
        puts problem.id 
      end
    end
  end
  
end
