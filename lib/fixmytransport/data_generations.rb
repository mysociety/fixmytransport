
module FixMyTransport

  # Functions for transport models that are loaded regularly from external data sources - these models
  # are versioned using the concept of a 'data generation' - a set of data loaded at one time that
  # is internally consistent, and supercedes previous data generations.
  module DataGenerations

    @@data_generation_models = []
    mattr_accessor :data_generation_models


    def self.included(base)
      base.send :extend, ClassMethods
    end

    # TODO: Find a better way to preload all models controlled by data generations
    def self.preload_all_models
      Dir[ File.join(RAILS_ROOT,'app','models','*.rb') ].map { |file| require_dependency file }
    end

    # Will set the scope to the generation passed on each model in the
    # models_to_set_generation_on parameter, and then yield the block
    def self.set_generation(models_to_set_generation_on, generation, &block)
      if models_to_set_generation_on.empty?
        yield
      else
        current_model = models_to_set_generation_on.pop
        current_model.in_generation(generation) do
          self.set_generation(models_to_set_generation_on, generation, &block)
        end
      end
    end

    def self.models_existing_in_data_generations
      # Make sure all models are loaded - as Rails uses lazy loading, some might only
      # be loaded in the context of the block passed - and we need to set the scope on them first
      self.preload_all_models
      self.data_generation_models
    end

    # Set the scope to the generation passed for all models controlled by data generations
    def self.in_generation(generation, &block)
      # make a copy of the list of models that exist in data generations
      models_to_set_generation_on = Array.new(self.models_existing_in_data_generations)
      # call the recursive function to set the generation scope on each of them
      self.set_generation(models_to_set_generation_on, generation, &block)
    end

    module ClassMethods

      def exists_in_data_generation(options={})

        # Record that this model is scoped by data generations
        FixMyTransport::DataGenerations.data_generation_models << self

        cattr_accessor :data_generation_options_hash
        # Want this not to be inherited by instances
        class << self
          attr_accessor :replayable
        end
        self.data_generation_options_hash = options
        send :include, InstanceMethods

        self.class_eval do
          # This default scope hides any models that belong to past or future data generations.
          default_scope :conditions => [ ["#{quoted_table_name}.generation_low <= ?",
                                          "AND #{quoted_table_name}.generation_high >= ?"].join(" "),
                                         CURRENT_GENERATION, CURRENT_GENERATION ]
          # These callbacks set the data generation and persistent columns to the current generation
          # and a new persistent_id if no value has been set on them
          before_validation :set_persistent_id
          before_create :set_generations
          validate :persistent_id_unique_in_generation

          def set_generations
            self.generation_low = CURRENT_GENERATION if self.generation_low.nil?
            self.generation_high = CURRENT_GENERATION if self.generation_high.nil?
          end

          def set_persistent_id
            self.persistent_id = self.class.next_persistent_id if self.persistent_id.nil?
          end

          def persistent_id_unique_in_generation
            self.field_unique_in_generation(:persistent_id)
          end

        end

        def next_persistent_id
          count_by_sql("SELECT NEXTVAL('#{table_name}_persistent_id_seq')")
        end

        # Reorder any slugs that existed in the previous generation, but have been
        # given a different sequence by the arbitrary load order
        def normalize_slug_sequences(data_generation)

          # Look for any instances where the slug and scope are the same for a previous version of
          # an object, and the version in this generation, but the sequences are different
          results = Slug.connection.execute("SELECT distinct slugs_new.name, slugs_new.scope
                                           FROM slugs as slugs_old, slugs as slugs_new,
                                           #{quoted_table_name} as sluggable_old,
                                           #{quoted_table_name} as sluggable_new
                                           WHERE slugs_old.sluggable_type = '#{self.to_s}'
                                           AND slugs_new.sluggable_type = '#{self.to_s}'
                                           AND slugs_old.sluggable_id = sluggable_old.id
                                           AND slugs_new.sluggable_id = sluggable_new.id
                                           AND slugs_new.generation_low = #{data_generation}
                                           AND slugs_old.generation_low = #{data_generation-1}
                                           AND (slugs_new.scope = slugs_old.scope
                                           OR slugs_new.scope is null and slugs_old.scope is null)
                                           AND (sluggable_new.previous_id = sluggable_old.id
                                           OR  sluggable_new.id = sluggable_old.id)
                                           AND (slugs_old.sequence != slugs_new.sequence
                                                AND slugs_old.name = slugs_new.name)")
          results.each do |name,slug_scope|
            condition_string = "slugs.name = ?"
            params = [name]
            if slug_scope
              condition_string += " AND slugs.scope = ?"
              params << slug_scope
            end
            instances = self.find(:all, :include => :slug, :conditions => [condition_string] + params)
            instances = instances.sort_by(&:slug_sequence_in_previous_generation)

            instances.each do |instance|
              instance.slug.destroy
              instance.slug = nil
            end
            instances.each do |instance|
              instance.save
            end
          end
        end

      end

      # Perform a block of code ignoring data generations
      def in_any_generation(&block)
        self.with_exclusive_scope do
          yield
        end
      end

      # Perform a block of code in the context of the data generation passed
      def in_generation(generation_id, &block)
        self.with_exclusive_scope do
          condition_string = ["#{quoted_table_name}.generation_low <= ?",
                              "AND #{quoted_table_name}.generation_high >= ?"].join(" ")
          self.with_scope(:find => {:conditions => [ condition_string, generation_id, generation_id ]}) do
             yield
          end
        end
      end

      def manual_remaps
        @manual_mapping_hash = get_manual_remaps unless defined? @manual_mapping_hash
        @manual_mapping_hash
      end

      def get_manual_remaps
        mappings = DataGenerationMapping.find(:all, :conditions => ['old_generation_id = ?
                                                                     AND new_generation_id = ?
                                                                     AND model_name = ?',
                                                                     PREVIOUS_GENERATION,
                                                                     CURRENT_GENERATION,
                                                                     self.to_s])
        mapping_hash = {}
        mappings.each do |mapping|
          mapping_hash[mapping.old_model_hash] = mapping.new_model_hash
        end
        mapping_hash
      end

      # If the find_params passed would have matched an instance in the previous generation
      # return that instance (if it is valid in the current generation), or its successor, if
      # it has one
      def find_successor(*find_params)
        previous = nil
        self.in_generation(PREVIOUS_GENERATION) do
          previous = self.find(*find_params)
        end
        if previous
          return previous if previous.generation_high >= CURRENT_GENERATION
          successor = self.find(:first, :conditions => ['previous_id = ?', previous.id])
          return successor if successor
          if remap_identity_hash = manual_remaps[previous.identity_hash]
            return self.find(:first, :conditions => remap_identity_hash)
          end
        end
        return nil
      end

    end

    module InstanceMethods

      # An identity hash identifies what is essentially the same object over different
      # generations of data, when the object id may be different.
      def get_identity_hash
        identity_hash = self.identity_hash()
        identity_type = :permanent
        if identity_hash.values.all?{ |value| value.blank? }
          identity_hash = self.temporary_identity_hash()
          identity_type = :temporary
          if identity_hash.values.all?{ |value| value.blank? }
            raise "#{self} has neither permanent or temporary identity values"
          end
        end
        return { :identity_hash => identity_hash,
                 :identity_type => identity_type }
      end

      def identity_hash
        if !self.class.data_generation_options_hash[:identity_fields]
          return {}
        else
          make_id_hash(self.class.data_generation_options_hash[:identity_fields])
        end
      end

      def temporary_identity_hash
        if !self.class.data_generation_options_hash[:temporary_identity_fields]
          raise "No temporary identity fields have been defined for #{self.class.to_s}"
        end
        make_id_hash(self.class.data_generation_options_hash[:temporary_identity_fields])
      end

      def make_id_hash(field_list)
        id_hash = {}
        field_list.each do |identity_field|
          id_hash[identity_field] = self.send(identity_field)
        end
        id_hash
      end

      def replayable
        if (!self.class.replayable.nil?) && self.class.replayable == false
          return false
        else
          return true
        end
      end

      # Validation method checking that a field is unique within a given data generation.
      # Supplying a :scope option constrains the check to include only objects whose values
      # for the scope option fields in the database are the same as the current object's
      def field_unique_in_generation(field, options={})
        value = self.send(field)
        return if value.blank?
        condition_string = "#{field} = ?"
        params = [value]
        if self.id
          condition_string += " AND id != ?"
          params << self.id
        end
        if !options[:scope].nil?
          if !options[:scope].is_a?(Array)
            options[:scope] = [ options[:scope] ]
          end
          options[:scope].each do |scope_element|
            scope_value = self.send(scope_element)
            if scope_value.nil?
              condition_string += " AND #{scope_element} IS NULL"
            else
              condition_string += " AND #{scope_element} = ?"
              params << scope_value
            end
          end
        end
        if existing = self.class.find(:first, :conditions => [condition_string] + params)
          errors.add(field,  ActiveRecord::Error.new(self, field, :taken).to_s)
        end
      end


      # Get the sequence of the slug from the version of this model in the previous
      # data generation. If there was none, return one more than the highest sequence
      # number for models with this slug in the previous generation
      def slug_sequence_in_previous_generation
        raise "This model does not use friendly_id slugs" unless self.class.uses_friendly_id?
        if self.previous()
          # did this object previously have the same slug and scope? If so, return the sequence
          # it used to have
          condition_string = "sluggable_id = ? and sluggable_type = ?"
          params = [self.previous.id, self.class.to_s]
          if self.slug.scope
            condition_string += " and scope = ?"
            params << self.slug.scope
          end
          previous_slug = nil
          Slug.in_generation(PREVIOUS_GENERATION) do
            previous_slug = Slug.find(:first, :conditions => [condition_string] + params)
          end
          return previous_slug.sequence if previous_slug
        end
        # If it didn't have the same slug and scope, return an integer one bigger than the
        # maximum sequence that used to exist for the slug and scope, or 1 if this slug and
        # scope didn't exist in the previous generation
        condition_string = "name = ? and sluggable_type = ?"
        params = [self.slug.name, self.class.to_s]
        if self.slug.scope
          condition_string += " and scope = ?"
          params << self.slug.scope
        end
        max_previous_slug = nil
        Slug.in_generation(PREVIOUS_GENERATION) do
          max_previous_slug = Slug.find(:first, :conditions => [condition_string] + params,
                                                :order => 'sequence desc')
        end
        if max_previous_slug
          return max_previous_slug.sequence + 1
        else
          return 1
        end
      end

      def previous
        if self.generation_low <= PREVIOUS_GENERATION
          return self
        end
        if self.previous_id
          self.class.in_generation(PREVIOUS_GENERATION) do
            return self.class.find(previous_id)
          end
        end
        return nil
      end

      def in_current_data_generation?
        if self.generation_high >= CURRENT_GENERATION
          return true
        else
          return false
        end
      end

    end
  end
end


