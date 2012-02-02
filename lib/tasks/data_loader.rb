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

  def check_for_model
    unless ENV['MODEL']
      usage_message "usage: This task requires MODEL=model_name"
    end
  end

  def check_for_generation
    unless (ENV['GENERATION'] && ENV['GENERATION'].to_i > 0)
      usage_message "usage: This task requires GENERATION=generation"
    end
  end

  def check_new_generation
    # Fail if the CURRENT_GENERATION param set from the config already exists in the database
    # or if it is not one more than the highest existing data generation id
    expected_generation = DataGeneration.maximum(:id) + 1
    if CURRENT_GENERATION != expected_generation
      usage_message "Error: In order to load a new transport data generation, you must set the
CURRENT GENERATION configuration parameter to a number one more
than the highest existing data generation (currently you should
set it to #{expected_generation})"
    end
  end

  def get_previous_generation
    check_for_generation()
    ENV['GENERATION'].to_i - 1
  end

  def check_verbose
    verbose = (ENV['VERBOSE']== 1) ? true : false
  end

  def check_dryrun
    dryrun = (ENV['DRYRUN']=='0') ? false : true
    if dryrun
      puts "Running in dryrun mode"
    end
    dryrun
  end

  def run_in_shell(command, index)
    shell = Session::Shell.new
    shell.outproc = lambda{ |out| puts "process-#{index}: #{ out }" }
    shell.errproc = lambda{ |err| puts err }
    puts "Starting process #{index}"
    puts command
    shell.execute(command)
    shell.exit_status()
  end

  def parse_for_update(model, parser_class)
    check_for_file
    puts "Updating #{model} from #{ENV['FILE']}..."
    parser = parser_class.new
    parser.send("parse_#{model}".to_sym, ENV['FILE']) do |model|
      yield model
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