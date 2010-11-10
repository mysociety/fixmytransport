module DataLoader
  
  def usage_message message
    puts ''
    puts message
    puts ''
    exit 0
  end
  
  def check_for_file
    unless ENV['FILE']
      usage_message "usage: This task requires FILE=filename"
    end
  end
  
  def check_for_dir 
    unless ENV['DIR']
      usage_message "usage: This task requires DIR=dirname"
    end
  end
  
  def parse(model, parser_class, skip_invalid=true)
    check_for_file
    puts "Loading #{model} from #{ENV['FILE']}..."
    parser = parser_class.new 
    parser.send("parse_#{model}".to_sym, ENV['FILE']) do |model| 
      begin
        model.save! 
      rescue ActiveRecord::RecordInvalid, FriendlyId::SlugGenerationError => validation_error
        if skip_invalid
          puts validation_error
          puts model.inspect
          puts 'Continuing....'
        else
          raise
        end
      end
    end
  end
  
end