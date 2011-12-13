namespace :temp do
  
  desc 'Set null boolean user flag values to default false'
  task :set_null_user_booleans => :environment do 
    
    boolean_flags = [:is_suspended, :is_admin, :is_expert]
    boolean_flags.each do |boolean_flag|
      User.find_each(:conditions => ["#{boolean_flag} is null"]) do |user|
        puts "setting #{boolean_flag} to false on #{user.id}"
        user.update_attribute(boolean_flag, false)
      end
    end
  end
  
  desc 'Populate comment counter cache'
  task :populate_comments_counter_cache => :environment do 
    User.find_each do |user|
      puts "#{user.id} #{user.comments.length}"
      user.update_attribute(:comments_count, user.comments.length)
    end
  end
  
end