namespace :temp do
  
  desc 'dump out list of problems'
  task :dump_out_problem_with_desc => :environment do 
  
    i = 0  
    Problem.confirmed.find_each() do |p|
      i = i+1
      puts ">>>#{p.id}\t#{p.created_at}\t#{p.status}\t#{p.transport_mode_text}\t#{p.subject}\t#{p.location.name}\t#{p.description}\n"
    end

  puts "\ntotal (confirmed) problems: #{i}\n"
  end

  desc 'Populate comment counter cache'
  task :populate_comments_counter_cache => :environment do 
    User.find_each do |user|
      puts "#{user.id} #{user.comments.length}"
      user.update_attribute(:comments_count, user.comments.length)
    end
  end
  
  task :find_custom_responsibilities => :environment do 
    Problem.visible.find_each do |problem|
      if problem.responsible_organizations.any?{ |org| !problem.location.responsible_organizations.include?(org) }
        puts problem.id 
      end
    end
  end
  
end
