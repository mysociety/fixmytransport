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
  
end
