module DataLoader
  
  def check_for_file
    unless ENV['FILE']
      puts ''
      puts "usage: This task requires FILE=filename"
      puts ''
      exit 0
    end
  end
  
  def check_for_dir 
    unless ENV['DIR']
      puts ''
      puts "usage: This task requires DIR=dirname"
      puts ''
      exit 0
    end
  end
  
  def parse(model, parser_class, skip_invalid=true)
    check_for_file
    puts "Loading #{model} from #{ENV['FILE']}..."
    parser = parser_class.new 
    parser.send("parse_#{model}".to_sym, ENV['FILE']) do |model| 
      begin
        model.save! 
      rescue ActiveRecord::RecordInvalid => validation_error
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