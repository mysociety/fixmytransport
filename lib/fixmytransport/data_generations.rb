
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
        conditions = current_model.data_generation_conditions(generation)
        current_model.send(:with_scope, :find => {:conditions => conditions}) do
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

        self.instance_eval do
          # A flag we can use to check if classes are versioned by data generations
          def versioned_by_data_generations?
            true
          end

          def data_generation_conditions(generation)
            [ ["#{quoted_table_name}.generation_low <= ?",
               "AND #{quoted_table_name}.generation_high >= ?"].join(" "),
               generation, generation ]
          end

          def next_persistent_id
            count_by_sql("SELECT NEXTVAL('#{table_name}_persistent_id_seq')")
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
            previous = self.in_generation(PREVIOUS_GENERATION).find(*find_params)
            if previous
              return previous if previous.generation_high >= CURRENT_GENERATION
              successor = self.current.find(:first, :conditions => ['previous_id = ?', previous.id])
              return successor if successor
              if remap_identity_hash = manual_remaps[previous.identity_hash]
                return self.current.find(:first, :conditions => remap_identity_hash)
              end
            end
            return nil
          end

        end

        self.class_eval do

          # This scope hides any model that is not active in the generation specified
          named_scope :in_generation, lambda { |generation| { :conditions => self.data_generation_conditions(generation) }}
          # This scope hides any model that is not active in the current generation
          named_scope :current, :conditions => self.data_generation_conditions(CURRENT_GENERATION)

          # These callbacks set the data generation and persistent columns to the current generation
          # if no value has been set on them, and add a new persistent id if none has been set
          before_validation :set_persistent_id, :set_generations
          validates_presence_of :persistent_id
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

    end
  end
end


