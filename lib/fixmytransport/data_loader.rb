module FixMyTransport

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
      return ENV['FILE']
    end

    def check_for_dir
      unless ENV['DIR']
        usage_message "usage: This task requires DIR=dirname"
      end
      return ENV['DIR']
    end

    def check_for_model
      unless ENV['MODEL']
        usage_message "usage: This task requires MODEL=model_name"
      end
      return ENV['MODEL']
    end

    def check_for_generation
      unless (ENV['GENERATION'] && ENV['GENERATION'].to_i > 0)
        usage_message "usage: This task requires GENERATION=generation"
      end
      return ENV['GENERATION'].to_i
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
      verbose = (ENV['VERBOSE']=='1') ? true : false
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

    def parse(model_class, parser_class, parse_method_name=nil, skip_invalid=true)
      check_for_file
      dryrun = check_dryrun()
      table_name = model_class.to_s.tableize
      puts "Loading #{table_name} from #{ENV['FILE']}..."

      if model_class.respond_to?(:replayable)
        previous_replayable_value = model_class.replayable
        model_class.replayable = false
      end

      parser = parser_class.new
      if parse_method_name.nil?
        parse_method_name = "parse_#{table_name}"
      end
      parser.send(parse_method_name.to_sym, ENV['FILE']) do |model|
        begin
          if ! dryrun
            model.save!
          end
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

      if model_class.respond_to?(:replayable)
        model_class.replayable = previous_replayable_value
      end
    end

    # Convert a list of fields to an attribute hash with values coming from an
    # instance of a model. Basic handling of association fields so that a field
    # "[association]_id" will have a value in the hash generated from instance.association.id
    # if instance.association is not nil, and nil otherwise
    def fields_to_attribute_hash(fields, instance)
      fields = fields.collect do |field|
        if field.to_s.ends_with?("_id")
          if association = instance.send(field.to_s[0...-3])
            [ field, association.id ]
          else
            [ field, nil ]
          end
        else
          [ field, instance.send(field) ]
        end
      end
      Hash[ *fields.flatten ]
    end

    # Generate a string from a model instance that gives model type, id and certain fields and values
    def reference_string(model_class, instance, fields)
      reference_string = "#{model_class} #{instance.id}"
      reference_string += " (#{fields_to_attribute_hash(fields, instance).inspect})"
    end

    # Load a new model instance into a generation, creating a new record in the new generation and linking it
    # to any previous record representing the same entity.
    # field_hash has the following keys:
    # :identity_fields - Fields that determine the identity of the instance - i.e. if the values of these fields
    # are the same, this is fundamentally the same thing
    # :deletion_field - a field that can indicate that the record has been deleted
    # :deletion_value - the value of the deletion_field that indicates deletion
    # Note that if the model is also versioned using papertrail to document local changes, changes
    # made by this function will be recorded as non-replayable, as they are assumed to have been
    # produced by loading data from the official source.
    def load_instances_in_generation(model_class, parser, &block)
      verbose = check_verbose()
      dryrun = check_dryrun()
      generation = ENV['GENERATION']
      previous_generation = get_previous_generation()
      puts "Loading #{model_class}" if verbose

      field_hash = model_class.data_generation_options_hash
      identity_fields = field_hash[:identity_fields]
      deletion_field = field_hash[:deletion_field]
      deletion_value = field_hash[:deletion_value]
      table_name = model_class.to_s.tableize
      counts = { :deleted => 0,
                 :updated_new_record => 0,
                 :new => 0 }

      # Store any changes as not replayable - ie. not manual edits from our interface
      if model_class.respond_to?(:replayable)
        previous_replayable_value = model_class.replayable
        model_class.replayable = false
      end

      parse_for_update(table_name, parser) do |instance|
        # do any model-specific instance level things
        if block_given?
          yield instance
        end

        # discard if actually deleted
        if deletion_field && instance.send(deletion_field) == deletion_value
          puts "Dropping deleted record #{reference_string(model_class, instance, identity_fields)}" if verbose
          counts[:deleted] += 1
          next
        end
        # Can we find this record in the previous generation?
        search_conditions = fields_to_attribute_hash(identity_fields, instance)
        existing = model_class.in_generation(previous_generation).find(:first, :conditions => search_conditions)
        if existing
          puts "New record in this generation for existing instance #{reference_string(model_class, existing, identity_fields)}" if verbose
          # Associate the old generation record with the new generation record
          instance.previous_id = existing.id
          instance.persistent_id = existing.persistent_id
          counts[:updated_new_record] += 1
        else
          puts "New instance #{reference_string(model_class, instance, identity_fields)}" if verbose
          counts[:new] += 1
        end
        if ! dryrun
          instance.save!
        else
          if ! instance.valid?
            puts "ERROR: New instance is invalid:"
            puts instance.errors.full_messages.join("\n")
            exit(1)
          end
        end
      end
      puts "Totally new #{table_name}: #{counts[:new]}"
      puts "Updated #{table_name} (new record): #{counts[:updated_new_record]}"
      puts "Deleted #{table_name}: #{counts[:deleted]}"
      if model_class.respond_to?(:replayable)
        model_class.replayable = previous_replayable_value
      end
    end

  end
end
