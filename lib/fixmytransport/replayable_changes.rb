module FixMyTransport

  # Functions for extracting, viewing and replaying local data edits.
  # Relies on version data supplied by the paper_trail gem. Replayable changes are a mechanism to handle
  # data that is loaded regularly from an external source but which may contain errors. A replayable change
  # is a locally made change to an instance of a model that comes from some external data source. If the
  # data for that instance is subsequently updated from the external source, we can replay or reapply our
  # own changes to the updated data if they are still relevant.
  module ReplayableChanges

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods


      # Allow classes using acts_as_dag to also use paper_trail to track changes
      def paper_trail_with_dag()

        self.class_eval do

          # We want to record local changes using paper_trail, but acts_as_dag records field changes by
          # trying to set attributes to their previous value on a cloned copy of the instance. The count=
          # method is not available outside the acts_as_dag plugin, so the following methods are
          # monkey patches of methods provided by paper_trail allowing us to specify attributes that
          # do not need to be recorded.
          def unsettable_fields
            [:count]
          end

          def item_before_change
            previous = self.clone
            previous.id = id
            changes.each do |attr, ary|
              if !unsettable_fields.include?(attr.to_sym)
                previous.send "#{attr}=", ary.first
              end
            end
            previous
          end

          def object_to_string(object)
            attrs = object.attributes.select{ |attr, val| ! unsettable_fields.include?(attr.to_sym) }
            Hash[attrs].to_yaml
          end

        end

      end

      # Allow classes in data generations using acts_as_dag and paper_trail to set the 'replayable'
      # flag on a version depending on whether the link instance is direct or indirect.
      def replayable_with_dag()

        self.class_eval do

          # This method calls the replayable method provided in data_generations
          # and customizes it so that paper_trail versions created by the behind-the-scenes
          # creation and destruction of indirect links by acts_as_dag are not marked as replayable
          def replayable_with_direct_checks
            if replayable_without_direct_checks == false
              return false
            end
            if changes['direct'] == [true, false] || # making a direct link indirect
               changes['direct'] == [false, true] || # making an indirect link direct
               changes['direct'] == [nil, true] # creating a direct link.
              return true
            end
            return false
          end
          alias_method_chain :replayable, :direct_checks

        end

      end

    end

    # Mark as unreplayable local updates that don't contain changes to any significant fields.
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
        info_hash = get_changes(version, model_class, options, verbose)
        if info_hash.nil? || (info_hash[:changes].empty? && !(info_hash[:event] == 'destroy'))
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
    # as replayable. Changes are returned as a hash keyed by persistent_id. The values of the hash
    # are ordered lists of hashes containing details of the changes made. These hashes will have keys:
    # :version_id - the id of the Version model where this change was made
    # :date - datetime the change was made on
    # :event - create|update|destroy
    # :changes - the significant changes in the form { :attribute => [old_value, new_value] }
    def get_updates(model_class, only_replayable=true,date=nil, verbose=false)
      update_hash = {}
      options = model_class.data_generation_options_hash
      condition_string = "item_type = ?"
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
        info_hash = get_changes(version, model_class, options, verbose)
        if info_hash && (info_hash[:event] == 'destroy' || !info_hash[:changes].empty?)
          persistent_id = info_hash.delete(:item_persistent_id)
          if update_hash[persistent_id].nil?
            update_hash[persistent_id] = []
          end
          update_hash[persistent_id] << info_hash
        end
      end
      return update_hash
    end

    # Get a hash describing a set of significant changes out of a version model.
    # :version_id - the id of the Version model where this change was made
    # :date - datetime the change was made on
    # :event - create|update|destroy
    # :changes - the significant changes in the form { attribute => [old_value, new_value] }
    # :persistent_id - the persistent_id of the model being changed.
    # The options param passed should be the data_generation_options_hash of the model class
    def get_changes(version, model_class, options, verbose)
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
                       :version_id => version.id }
      case version.event
      when 'create'
        if version.next()
          version_model = version.next.reify()
        else
          begin
            version_model = model_class.find(version.item_id)
          rescue ActiveRecord::RecordNotFound => e
            puts ["New #{model_name} with id #{version.item_id} created in version #{version.id}",
                  "but no further history or #{model_name} exists"].join(" ") if verbose
            return nil
          end
        end
        diff = model_class.new.diff(version_model)
        diff = remove_ignored(diff, keys_to_ignore, values_to_ignore)
        details_hash.update( :changes => diff )
      when 'update'
        version_model = version.reify()
        next_version = version_model.next_version
        if next_version.nil?
          begin
            next_version = model_class.find(version.item_id)
          rescue ActiveRecord::RecordNotFound => e
            puts ["#{model_name} with id #{version.item_id} updated in version #{version.id}",
                  "but no further history or #{model_name} exists"].join(" ") if verbose
            return nil
          end
        end
        diff = version_model.diff(next_version)
        diff = remove_ignored(diff, keys_to_ignore, values_to_ignore)
        details_hash.update( :changes => diff )
      when 'destroy'
        version_model = version.reify()
        details_hash.update( :changes => {} )
      else
        raise "Unknown version event for version id #{version.id}: #{version.event}"
      end
      details_hash[:item_persistent_id] = version_model.persistent_id ? version_model.persistent_id : version_model.id
      return details_hash
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
      update_hash = get_updates(model_class, only_replayable=true, date=nil, verbose=verbose)
      model_name = model_class.to_s.downcase
      update_hash.each do |persistent_id, changes|
        puts "Checking changes for persistent_id #{persistent_id}" if verbose

        # Try to find the object in the current generation
        existing = model_class.current.find_by_persistent_id(persistent_id)
        if ! existing
          puts "Can't find current #{model_name} to update for persistent_id #{persistent_id} (#{changes.first[:version_id]})" if verbose
          if destruction = changes.find{ |change| change[:event] == 'destroy'}
            # Double check to see if a new instance matching the identity hash has been loaded
            # after the instance in the previous generation was deleted (thus not getting the
            # same persistent id)
            destroyed_instance = Version.find(destruction[:version_id]).reify()

            existing = model_class.find_in_generation_by_identity_hash(destroyed_instance, CURRENT_GENERATION)
            if ! existing
              puts ["Can't find any #{model_name} to match destroyed #{model_name}",
                    "with persistent_id #{persistent_id} (version #{destruction[:version_id]})"].join(" ") if verbose
            end
          elsif changes.first[:event] == 'create'
            # This was a locally created object, so find the model in the previous generation
            puts "#{model_name} created locally. Looking in previous generation." if verbose
            existing = model_class.in_generation(PREVIOUS_GENERATION).find_by_persistent_id(persistent_id)
            if ! existing
              puts ["Can't find locally created #{model_name} in previous generation to update",
                    "for persistent_id #{persistent_id}"].join(" ") if verbose
            end
          end
        end
        next if ! existing
        changes.each do |details_hash|
          change_list = apply_changes(model_name, details_hash, existing, dryrun, verbose, change_list)
        end
      end
      return change_list
    end

    # Apply a set of changes extracted from replayable updates to a model instance
    def apply_changes(model_name, change_details, instance, dryrun, verbose, change_list)
      event = change_details[:event]
      changes = change_details[:changes]
      version_id = change_details[:version_id]
      previous_version = Version.find(version_id)
      previous_version.replayable = false
      instance.replay_of = previous_version.id
      case event
      when 'create'
        changes[:generation_high] = [PREVIOUS_GENERATION, CURRENT_GENERATION]
        applied_changes = apply_changeset(model_name, changes, instance, verbose)
        if !applied_changes.empty?
          change_list << { :event => :create,
                           :model => instance,
                           :changes => changes }
        end
      when 'update'
        applied_changes = apply_changeset(model_name, changes, instance, verbose)
        if !applied_changes.empty?
          change_list << { :event => :update,
                           :model => instance,
                           :changes => applied_changes }
        end
      when 'destroy'
        puts "Destroying #{model_name} #{instance.id} (version id #{version_id} #{change_details[:date]})"
        change_list <<  { :event => :destroy,
                          :model => instance }
      end
      if ! dryrun
        if event == 'destroy'
          instance.destroy
        else
          instance.save!
        end
        previous_version.save!
      end
      return change_list
    end

    def apply_changeset(model_name, changes, instance, verbose)
      applied_changes = {}
      changes.each do |attribute, values|
        from_value, to_value = values
        current_value = instance.send(attribute)
        if from_value == current_value
          puts "#{model_name} (#{instance.id}) updating #{attribute} from #{from_value} to #{to_value}" if verbose
          instance.send("#{attribute}=", to_value)
          applied_changes[attribute] = values
        elsif to_value == current_value
          puts ["Discarding change of #{attribute} from #{from_value} -> #{to_value} as obsolete",
                "(currently #{current_value})"].join(" ") if verbose
        else
          puts ["Discarding change of #{attribute} from #{from_value} -> #{to_value} as probably",
                "obsolete (currently #{current_value})"].join(" ") if verbose
        end
      end
      return applied_changes
    end

  end

end