namespace :temp do
  
  desc "Populate the operator contacts table with emails from operators" 
  task :populate_operator_contacts => :environment do 
    Operator.find_each(:conditions => "email is not null") do |operator|      
      if ! operator.email.blank? 
        puts operator.inspect
        operator_contact = OperatorContact.new(:email => operator.email, 
                                               :confirmed => operator.email_confirmed,
                                               :operator => operator, 
                                               :category => 'Other', 
                                               :notes => operator.notes)
        operator_contact.save!
        
        # transfer the sent email and outgoing message associations
        operator.sent_emails.each do |sent_email|
          sent_email.recipient = operator_contact
          sent_email.save!
        end
        operator.outgoing_messages.each do |outgoing_message|
          outgoing_message.recipient = operator_contact
          outgoing_message.save!
        end
      end
    end
  end
end
