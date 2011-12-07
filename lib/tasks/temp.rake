namespace :temp do
  
  desc 'dump out list of problems'
  task :dump_out_problems => :environment do 
    
    puts "Hello"
    Problem.confirmed.find_each() do |p|
        puts "#{p.id}\t#{p.created_at}\t#{p.subject}\t#{p.transport_mode_text}\t#{p.description}\n"
    end
    puts "done: records:" 
  end
  
end