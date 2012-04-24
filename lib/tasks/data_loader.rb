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
  def reference_string(model_class, instance, fields)
    reference_string = "#{model_class} #{instance.id}"
    reference_string += " ("
    reference_string +=  fields.map{ |field| "#{field}=#{instance.send(field)}"}.join(", ")
    reference_string += ")"
  end

  # Apply a set of changes extracted from replayable updates to a model instance
  def apply_changes(model_name, instance, changes, dryrun, verbose, change_list)
    changes.each do |attribute, values|
      from_value, to_value = values
      current_value = instance.send(attribute)
      if from_value == current_value
        puts "#{model_name} (#{instance.id}) updating #{attribute} from #{from_value} to #{to_value}" if verbose
        instance.send("#{attribute}=", to_value)
        change_list << { :event => :update,
                         :model => instance,
                         :attribute => attribute,
                         :from_value => from_value,
                         :to_value => to_value }
      elsif to_value == current_value
        puts ["Discarding change of #{attribute} from #{from_value} -> #{to_value} as obsolete",
              "(currently #{current_value})"].join(" ") if verbose
      else
        puts ["Discarding change of #{attribute} from #{from_value} -> #{to_value} as probably",
              "obsolete (currently #{current_value})"].join(" ") if verbose
      end
      if ! dryrun
        instance.save!
      end
    end
    return change_list
  end

  # Create a search hash that will find a model with permanent identity fields whose
  # values match those of a temporary identity hash
  def temp_to_perm_search_hash(model_class, temporary_identity_hash)
    temp_to_perm_mappings = model_class.data_generation_options_hash[:temp_to_perm]
    search_hash = {}
    temporary_identity_hash.each do |key, value|
      search_hash[temp_to_perm_mappings[key]] = value
    end
    return search_hash
  end

  def find_instance_for_temporary_identity(model_class, identity_hash, verbose)
    model_name = model_class.to_s.downcase
    # Can we map this to an object in this generation with a permanent id hash?
    if model_class.data_generation_options_hash.has_key?(:temp_to_perm)
      permanent_hash = temp_to_perm_search_hash(model_class, identity_hash)
      puts "Looking for #{model_name} with #{permanent_hash.inspect}" if verbose
      existing = model_class.find(:first, :conditions => permanent_hash)
    else
      existing = nil
    end
    if ! existing
      puts "Looking for #{model_name} with #{identity_hash.inspect}" if verbose
      # Can we map this to an object in this generation with a temporary id hash?
      existing = model_class.find(:first, :conditions => identity_hash)
    end
    return existing
  end

  def find_model_by_identity_hash(model_class, identity_hash, identity_type, verbose)
    if identity_type == :temporary
      existing = find_instance_for_temporary_identity(model_class, identity_hash, verbose)
    else
      existing = model_class.find(:first, :conditions => identity_hash)
    end
    return existing
  end

  # Add a hash of changes to a migration path, so adding the change {:name => ['Bob', 'Ken']}
  # to the migration {:name => ['John', 'Bob']} will result in {:name => ['John', 'Bob', 'Ken']}.
  # Adding the change {:name => ['Ken', 'Bob']} would raise an error as there's an inconsistency
  # in the chain
  def add_changes_to_migration(migration_paths, changes)
    changes.each do |attribute, change|
      from_value, to_value = change
      if migration_paths[attribute].nil?
        migration_paths[attribute] = change
      else
        if migration_paths[attribute].last != from_value
          raise "Broken chain when adding #{change.inspect} for #{attribute} to #{migration_paths.inspect}"
        end
        migration_paths[attribute] << to_value
      end
    end
    return migration_paths
  end

  # Replay the significant updates that have been made locally to instances of a model class
  # versioned with papertrail.
  def replay_updates(model_class, dryrun=true, verbose=false)
    change_list = []
    if ! model_class.respond_to?(:replayable)
      puts "This model is not versioned in data generations. Updates cannot be replayed."
      exit(0)
    end
    if (! model_class.respond_to?(:paper_trail_active)) || !model_class.paper_trail_active
      puts "This model does not store a history of local edits. Updates cannot be replayed."
      exit(0)
    end
    # Don't want to add more replayable changes based on applying these, so replayable
    # attribute on models should be false
    previous_replayable_value = model_class.replayable
    model_class.replayable = false
    update_hash = get_updates(model_class, only_replayable=true, date=nil, verbose=verbose)
    model_name = model_class.to_s.downcase
    update_hash.each do |identity, changes|
      identity_type = identity[:identity_type]
      identity_hash = identity[:identity_hash]
      puts "Checking changes for #{identity_hash.inspect}" if verbose

      # Try to find the object in the current generation
      existing = find_model_by_identity_hash(model_class, identity_hash, identity_type, verbose)
      if ! existing
        puts "Can't find current #{model_name} to update for #{identity_hash.inspect}" if verbose
        if changes.first[:event] == 'create'
          # This was a locally created object, so find the model in the previous generation
          puts "#{model_name} created locally. Looking in previous generation." if verbose
          model_class.in_generation(PREVIOUS_GENERATION) do
            existing = model_class.find(:first, :conditions => identity_hash)
          end
          if ! existing
            puts ["Can't find locally created #{model_name} in previous generation to update",
                  "for #{identity_hash.inspect}"].join(" ") if verbose
          end
        end
      end
      next if ! existing

      # Chain together the changes over time for each attribute to produce a migration path
      # from the value it started at to the value it ended at
      migration_paths = {}
      changes.each do |details_hash|
        event = details_hash[:event]
        date = details_hash[:date]
        changes = details_hash[:changes]
        case event
        when 'create'
          if identity_type == :permanent
            raise "New #{model_name} created with permanent identifiers"
          else
            # remove temporary identity values for creation events - either the object
            # we found already has those identifiers, or it has permanent identifiers,
            # so doesn't need them
            identity_hash.each { |key, value| changes.delete(key) }
            migration_paths[:generation_high] = [PREVIOUS_GENERATION, CURRENT_GENERATION]
          end
          add_changes_to_migration(migration_paths, changes)
        when 'update'
          add_changes_to_migration(migration_paths, changes)
        when 'destroy'
          puts "Destroying #{model_name} #{existing.id}"
          change_list <<  { :event => :destroy, :model => existing }
          if ! dryrun
            existing.destroy
          end
        end
      end

      # reduce the migration path for each attribute to a simple [from_value, to_value]
      # list by taking the start and end point of each migration, and removing
      # any migration paths that end with the same value they started with. An alternative
      # here would be to keep the paths and have apply_changes apply the last value whenever
      # the current value of the instance matches any previous value in the migration
      migration_paths.each do |attribute, values|
        if values.first != values.last
          migration_paths[attribute] = [values.first, values.last]
        else
          migration_paths.delete(attribute)
        end
      end
      change_list = apply_changes(model_name, existing, migration_paths, dryrun, verbose, change_list)
    end
    model_class.replayable = previous_replayable_value
    return change_list
  end

  # Update a hash, removing keys, and values specified
  def remove_ignored(diff, keys_to_ignore, values_to_ignore)
    keys_to_ignore.each do |key|
      diff.delete(key)
    end
    diff.each do |key, value|
      values_to_ignore.each do |value_to_ignore|
        if value == value_to_ignore
          diff.delete(key)
        end
      end
    end
    return diff
  end

  # Get a hash describing a set of significant changes out of a version model.
  # The hash will have two keys - :identity, whose values is a hash whose keys in turn are
  # :identity_hash - a hash of identifying key value pairs for the object being changed,
  # and :identity_type, with a value of :temporary or :permanent, indicating whether that hash
  # should uniquely identify the thing being referenced with respect to external datasets, or
  # is just a temporary id hash generated from internal identifiers.
  # The second key of the hash is :details, with keys as follows:
  # :id - the id of the Version model where this change was made
  # :date - datetime the change was made on
  # :event - create|update|destroy
  # :changes - the significant changes in the form { attribute => [old_value, new_value] }
  # The options param passed should be the data_generation_options_hash of the model class
  def get_changes(version, model_class, only_replayable, options, verbose)
    info_hash = {}
    model_name = model_class.to_s.downcase
    table_name = model_class.to_s.tableize
    # ignore changes to fields that are automatically updated
    keys_to_ignore = [:created_at, :updated_at, :loaded, :generation_low, :generation_high]
    # add any specific auto-updated fields from the model class
    keys_to_ignore += options[:auto_update_fields] if !options[:auto_update_fields].nil?

    # ignore any attribute changes from nil to blank or vice versa
    values_to_ignore = [[nil, ""], ["", nil]]

    details_hash = { :date => version.created_at,
                     :event => version.event,
                     :id => version.id }
    # make sure we can see all data generations - we will be looking for changes
    # that happened regardless of data generation
    model_class.send(:with_exclusive_scope) do
      case version.event
      when 'create'
        if only_replayable && !options[:temporary_identity_fields]
          raise "New #{table_name} have been created (e.g. id #{version.item_id}),
                 but there is no temporary id field defined"
        end
        if version.next()
          version_model = version.next.reify()
        else
          begin
            version_model = model_class.find(version.item_id)
          rescue ActiveRecord::RecordNotFound => e
            puts ["New #{model_name} with id #{version.item_id} created in version #{version.id}",
                  "but no further history or current #{model_name} exists"].join(" ") if verbose
            return nil
          end
        end
        info_hash[:identity] = version_model.get_identity_hash()
        diff = model_class.new.diff(version_model)
        diff = remove_ignored(diff, keys_to_ignore, values_to_ignore)
        details_hash.update( :changes => diff )
        info_hash[:details] = details_hash
      when 'update'
        version_model = version.reify()
        info_hash[:identity] =  version_model.get_identity_hash()
        next_version = version_model.next_version
        if next_version.nil?
          begin
            next_version = model_class.find(version.item_id)
          rescue ActiveRecord::RecordNotFound => e
            puts ["#{model_name} with id #{version.item_id} updated in version #{version.id}",
                  "but no further history or current #{model_name} exists"].join(" ") if verbose
            return nil
          end
        end
        diff = version_model.diff(next_version)
        diff = remove_ignored(diff, keys_to_ignore, values_to_ignore)
        details_hash.update( :changes => diff )
        info_hash[:details] = details_hash
      when 'destroy'
        version_model = version.reify()
        info_hash[:identity] =  version_model.get_identity_hash()
        details_hash.update( :changes => {} )
        info_hash[:details] = details_hash
      else
        raise "Unknown version event for version id #{version.id}: #{version.event}"
      end
    end
    return info_hash
  end

  # Retrieve a hash of significant updates made to instances of model_class from the versions table
  # populated by papertrail. If only_replayable is true, only return updates that have been marked
  # as replayable. Changes are returned as a hash keyed by a hash with two keys - :identity_hash -
  # a hash of identifying key value pairs for the object being changed, and :identity_type, with a
  # value of :temporary or :permanent, indicating whether that hash should uniquely identify the
  # thing being referenced with respect to external datasets, or is just a temporary id hash
  # generated from internal identifiers. The values of the hash are ordered lists of hashes containing
  # details of the changes made. These hashes will have keys:
  # :id - the id of the Version model where this change was made
  # :date - datetime the change was made on
  # :event - create|update|destroy
  # :changes - the significant changes in the form { :attribute => [old_value, new_value] }
  def get_updates(model_class, only_replayable=true,date=nil, verbose=false)
    update_hash = {}
    options = model_class.data_generation_options_hash
    condition_string = "item_type = ? "
    params = [model_class.to_s]
    if date
      condition_string += " AND date_trunc('day', created_at) = ?"
      params << date
    end
    if only_replayable
      condition_string += " AND replayable = ?"
      params << true
    end
    conditions = [condition_string] + params
    # get the list of changes for this model, assemble the hash structure, only adding
    # versions where some significant value has changed.
    updates = Version.find(:all, :conditions => conditions,
                                 :order => 'created_at asc')
    updates.each do |version|
      info_hash = get_changes(version, model_class, only_replayable, options, verbose)
      if info_hash && !info_hash[:details][:changes].empty?
        if update_hash[info_hash[:identity]].nil?
          update_hash[info_hash[:identity]] = []
        end
        update_hash[info_hash[:identity]] << info_hash[:details]
      end
    end
    return update_hash
  end

  # Mark as unreplayable local updates marked as replayable for a model class that refer to an
  # instance that does not exist and is not referred to by subsequent versions or don't contain
  # changes to any significant fields.
  def mark_unreplayable(model_class, dryrun, verbose)

    options = model_class.data_generation_options_hash
    condition_string = "item_type = ? AND replayable = ?"
    params = [model_class.to_s, true]
    conditions = [condition_string] + params

    # get the list of changes for this model, assemble the hash structure, only adding
    # versions where some significant value has changed.
    updates = Version.find(:all, :conditions => conditions,
                                  :order => 'created_at asc')
    updates.each do |version|
      info_hash = get_changes(version, model_class, only_replayable='t', options, verbose)
      if info_hash.nil? || (info_hash[:details][:changes].empty? && !(info_hash[:details][:event] == 'destroy'))
        puts "Marking #{version.id} #{version.inspect} as unreplayable" if verbose
        version.replayable = false
        if ! dryrun
          version.save
        end
      end
    end
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
    new_record_fields = field_hash[:new_record_fields]
    update_fields = field_hash[:update_fields]
    deletion_field = field_hash[:deletion_field]
    deletion_value = field_hash[:deletion_value]
    table_name = model_class.to_s.tableize
    counts = { :deleted => 0,
               :updated_existing_record => 0,
               :updated_new_record => 0,
               :new => 0 }
    diffs = {}

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


      instance.generation_low = generation
      instance.generation_high = generation
      # Can we find a record in the previous generation with few enough differences that we can update it
      # in place?
      change_in_place_fields = identity_fields + new_record_fields
      # discard if actually deleted
      if deletion_field && instance.send(deletion_field) == deletion_value
        puts "Dropping deleted record #{reference_string(model_class, instance, change_in_place_fields)}" if verbose
        counts[:deleted] += 1
        next
      end
      search_conditions = fields_to_attribute_hash(change_in_place_fields, instance)
      existing = nil
      model_class.in_generation(previous_generation) do
        existing = model_class.find(:first, :conditions => search_conditions)
      end
      # make a string we can use in output to identify the new instance by it's key attributes
      if existing
        puts "Updating and setting generation_high to #{generation} on #{reference_string(model_class, existing, change_in_place_fields)}" if verbose
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
        model_class.in_generation(previous_generation) do
          existing = model_class.find(:first, :conditions => search_conditions)
        end
        if existing
          puts "New record in this generation for existing instance #{reference_string(model_class, existing, change_in_place_fields)}" if verbose
          diff_hash = existing.diff(instance)
          significant_diff_hash = {}
          diff_hash.each do |key, value|
            if new_record_fields.include?(key)
              if diffs[key].nil?
                diffs[key] = 1
              else
                diffs[key] +=1
              end
              significant_diff_hash[key] = value
            end
          end
          puts significant_diff_hash.inspect if verbose
          # Associate the old generation record with the new generation record
          instance.previous_id = existing.id
          counts[:updated_new_record] += 1
        else
          puts "New instance #{reference_string(model_class, instance, change_in_place_fields)}" if verbose
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
    if model_class.respond_to?(:replayable)
      model_class.replayable = previous_replayable_value
    end
  end

end