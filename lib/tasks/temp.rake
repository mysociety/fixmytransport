require File.dirname(__FILE__) +  '/data_loader'
require File.dirname(__FILE__) +  '/../fixmytransport/geo_functions'

namespace :temp do

  desc 'Regenerate body text fields for incoming email' 
  task :regenerate_incoming_mail_texts => :environment do 
    IncomingMessage.find_each do |incoming_message|
      incoming_message.main_body_text(regenerate=true)
      incoming_message.main_body_text_folded(regenerate=true)
      incoming_message.save
    end
  end
  
end

