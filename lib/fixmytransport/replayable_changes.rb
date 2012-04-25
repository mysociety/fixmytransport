module FixMyTransport

  # Functions for extracting, viewing and replaying local data edits.
  # Relies on version data supplied by the paper_trail gem. Replayable changes are a mechanism to handle
  # data that is loaded regularly from an external source which may contain errors. A replayable change
  # is a locally made change to an instance of a model that comes from some external data source. If the
  # data for that instance is subsequently updated from the external source, we can replay or reapply our
  # own changes to the updated data if they are still relevant.
  module ReplayableChanges

    # Mark as unreplayable local updates marked as replayable for a model class that refer to an
    # instance that does not exist any more and is not referred to by subsequent versions or don't contain
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
        if info_hash && (info_hash[:details][:event] == 'destroy' || !info_hash[:details][:changes].empty?)
          if update_hash[info_hash[:identity]].nil?
            update_hash[info_hash[:identity]] = []
          end
          update_hash[info_hash[:identity]] << info_hash[:details]
        end
      end
      return update_hash
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
        change_list = apply_changes(model_name, existing, migration_paths, dryrun, verbose, change_list)
      end
      model_class.replayable = previous_replayable_value
      return change_list
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

    # Apply a set of changes extracted from replayable updates to a model instance
    def apply_changes(model_name, instance, changes, dryrun, verbose, change_list)
      changes.each do |attribute, values|
        values.each_cons(2) do |from_value, to_value|
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

  end

end