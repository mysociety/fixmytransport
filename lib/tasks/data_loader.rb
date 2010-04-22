module DataLoader
  
  def check_for_file taskname
    unless ENV['FILE']
      puts ''
      puts "usage: rake #{data_source}:load:#{taskname} FILE=filename"
      puts ''
      exit 0
    end
  end
  
  def parse(model, skip_invalid=true)
    check_for_file model
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