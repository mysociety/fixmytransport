namespace :temp do
  
  desc 'Move the associations on comments to a polymorphic field'
  task :make_comments_polymorphic => :environment do 
    Comment.find_each do |comment|
      puts "#{comment.id} #{comment.user_name}"
      if comment.campaign_update
        comment.commented = comment.campaign_update
      elsif comment.problem
        comment.commented = comment.problem
      else
        raise "Unknown commentable for comment #{comment.id}"
      end
      comment.save!
    end
  end
  

  desc "Create location searches from log files" 
  task :create_location_searches_from_log_files => :environment do 
    f = File.open("#{RAILS_ROOT}/../logs/production.log")
    prev = ''
    f.each do |line|
      if prev =~ /ProblemsController#find_stop/
        if match = /"name"=>"(.*?)"/.match(line)
          name = match[1]
          add_location_search({:name => name, :location_type => 'Stop/station'}, prev)
        end
      end
      if prev =~ /ProblemsController#find_train_route/
        from = nil
        to = nil

        if match = /"from"=>"(.*?)"/.match(line)
	        from = match[1]
        end
        if match = /"to"=>"(.*?)"/.match(line)
          to = match[1]
        end
        if !from.blank? && !to.blank?
          add_location_search({:from => from, :to => to, :location_type => 'Train route'}, prev)
        end
      end
      if prev =~ /ProblemsController#find_other_route/
        from = nil
        to = nil

        if match = /"from"=>"(.*?)"/.match(line)
          from = match[1]
        end
        if match = /"to"=>"(.*?)"/.match(line)
          to = match[1]
        end
        if !from.blank? && !to.blank?
          add_location_search({:from => from, :to => to, :location_type => 'Other route'}, prev)
        end
      end
      if prev =~ /ProblemsController#find_bus_route/

        if match = /"route_number"=>"(.*?)"/.match(line)
          number = match[1]
        end
        if match = /"area"=>"(.*?)"/.match(line)
          area = match[1]
        end
        if !number.blank? && !area.blank?
          add_location_search({:route_number => number, :area => area, :location_type => 'Bus route'}, prev)
        end
      end

      prev = line
    end
  end
  
  def add_location_search(attributes, prev)
    if match = /at (.*?)\)/.match(prev)
      date = match[1]
      puts "Adding location_search with #{attributes.inspect} #{date}"
      attributes[:active] = false
      attributes[:session_id] = 'xxx'
      attributes[:created_at] = DateTime.parse(date)
      attributes[:events] = []
      ls = LocationSearch.create(attributes)
    else
      raise "Couldn't find date in #{prev}"
    end
  end
end
