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

  # Convert a list of fields to an attribute hash with values coming from an
  # instance of a model. Basic handling of association fields so that a field
  # "[association]_id" will have a value in the hash generated from instance.association.id
  # if instance.associationis not nil, and nil otherwise
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
  def reference_string(model_type, instance, fields)
    reference_string = "#{model_type} #{instance.id}"
    reference_string += " ("
    reference_string +=  fields.map{ |field| "#{field}=#{instance.send(field)}"}.join(", ")
    reference_string += ")"
  end

  # Load a new model instance into a generation, checking for existing record in previous generation
  # and updating that or creating a new record in the new generation as appropriate
  # field_hash has the following keys:
  # :identity_fields - Fields that determine the identity of the instance - i.e. if the values of these fields
  # are the same, this is fundamentally the same thing
  # :new_record_fields - Fields that are significant enough that they require a new record if changed
  # e.g names, other fields used in slugs - we don't want any changes made to these fields to
  # leak into the previous generation
  # :update_fields - fields that should be updated if changed, but don't require a new record
  def load_instances_in_generation(model_type, parser, field_hash, &block)
    verbose = check_verbose()
    dryrun = check_dryrun()
    generation = ENV['GENERATION']
    previous_generation = get_previous_generation()
    identity_fields = field_hash[:identity_fields]
    new_record_fields = field_hash[:new_record_fields]
    update_fields = field_hash[:update_fields]
    deletion_field = field_hash[:deletion_field]
    deletion_value = field_hash[:deletion_value]
    table_name = model_type.to_s.tableize
    counts = { :deleted => 0,
               :updated_existing_record => 0,
               :updated_new_record => 0,
               :new => 0 }
    diffs = {}
    parse_for_update(table_name, parser) do |instance|

      # do any model-specific instance level things
      if block_given?
        yield instance
      end

      instance.generation_low = generation
      instance.generation_high = generation
      # Can we find a record in the previous generation with few enough differences that we can update it
      # in place?
      change_in_place_fields = identity_fields + new_record_fields
      # discard if actually deleted
      if deletion_field && instance.send(deletion_field) == deletion_value
        puts "Dropping deleted record #{reference_string(model_type, instance, change_in_place_fields)}" if verbose
        counts[:deleted] += 1
        next
      end
      search_conditions = fields_to_attribute_hash(change_in_place_fields, instance)
      existing = model_type.find_in_generation(previous_generation, :first, :conditions => search_conditions)
      # make a string we can use in output to identify the new instance by it's key attributes
      if existing
        puts "Updating and setting generation_high to #{generation} on #{reference_string(model_type, existing, change_in_place_fields)}" if verbose
        # update all the update fields
        update_fields.each do |field_name|
          existing.send("#{field_name}=", instance.send(field_name))
        end
        existing.generation_high = generation
        counts[:updated_existing_record] += 1
        if ! dryrun
          existing.save!
        else
          if ! existing.valid?
            puts "ERROR: Existing instance is invalid:"
            puts existing.errors.full_messages.join("\n")
            exit(1)
          end
        end
      else
        # Can we find this record at all in the previous generation?
        search_conditions = fields_to_attribute_hash(identity_fields, instance)
        existing = model_type.find_in_generation(previous_generation, :first, :conditions => search_conditions)
        if existing
          puts "New record in this generation for existing instance #{reference_string(model_type, existing, change_in_place_fields)}" if verbose
          diff_hash = existing.diff(instance)
          diff_hash.each do |key, value|
            if new_record_fields.include?(key)
              if diffs[key].nil?
                diffs[key] = 1
              else
                diffs[key] +=1
              end
            end
          end
          puts diff_hash.inspect if verbose
          # Associate the old generation record with the new generation record
          instance.previous_id = existing.id
          counts[:updated_new_record] += 1
        else
          puts "New instance #{reference_string(model_type, instance, change_in_place_fields)}" if verbose
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
    end
    puts "Totally new #{table_name}: #{counts[:new]}"
    puts "Updated #{table_name} (using existing record): #{counts[:updated_existing_record]}"
    puts "Updated #{table_name} (new record): #{counts[:updated_new_record]}"
    puts "Deleted #{table_name}: #{counts[:deleted]}"
    if ! diffs.empty?
      puts "New records were created for existing objects due to differences in the following fields:"
      diffs.each do |key, value|
        puts "#{key}: #{value} times"
      end
    end
  end

end