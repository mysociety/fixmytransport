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

end


