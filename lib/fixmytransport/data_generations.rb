# Functions for transport models that belong to data generations
module FixMyTransport

  module DataGenerations

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def exists_in_data_generation(options={})
        cattr_accessor :data_generation_options_hash
        # Want this not to be inherited by instances
        class << self
          attr_accessor :replayable
        end
        self.data_generation_options_hash = options
        send :include, InstanceMethods

        self.class_eval do
           # This default scope hides any models that belong to past or future data generations.
           default_scope :conditions => [ "#{quoted_table_name}.generation_low <= ?
                                           AND #{quoted_table_name}.generation_high >= ?",
                                           CURRENT_GENERATION, CURRENT_GENERATION ]
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

      # Set the scope of a find call to a specific generation
      def find_in_generation(generation_id, *params)
        self.with_exclusive_scope do
          self.with_scope(:find => {:conditions => [ "#{quoted_table_name}.generation_low <= ?
                                                      AND #{quoted_table_name}.generation_high >= ?",
                                                      generation_id, generation_id ]}) do
             find(*params)
          end
        end
      end

      # If the find_params passed would have matched an instance in the previous generation
      # return that instance (if it is valid in the current generation), or its successor, if
      # it has one
      def find_successor(*find_params)
        previous = self.find_in_generation(PREVIOUS_GENERATION, *find_params)
        if previous
          return previous if previous.generation_high >= CURRENT_GENERATION
          successor = self.find(:first, :conditions => ['previous_id = ?', previous.id])
          return successor if successor
        end
        return nil
      end

    end

    module InstanceMethods

      def identity_hash
        make_id_hash(self.class.data_generation_options_hash[:identity_fields])
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
          previous_slug = Slug.find_in_generation(PREVIOUS_GENERATION,
                                                  :first,
                                                  :conditions => [condition_string] + params)

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
        max_previous_slug = Slug.find_in_generation(PREVIOUS_GENERATION,
                                                :first,
                                                :conditions => [condition_string] + params,
                                                :order => 'sequence desc')
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
          return self.class.find_in_generation(PREVIOUS_GENERATION, previous_id)
        end
        return nil
      end

    end
  end
end


