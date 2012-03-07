# Functions for transport models that belong to data generations
module FixMyTransport

  module DataGenerations

    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods

      def exists_in_data_generation()
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
          names = Slug.connection.execute("SELECT distinct slugs_new.name
                                           FROM slugs as slugs_old, slugs as slugs_new,
                                                #{quoted_table_name} as sluggable_old,
                                                #{quoted_table_name} as sluggable_new
                                           WHERE slugs_old.sluggable_type = '#{self.to_s}'
                                           AND slugs_new.sluggable_type = '#{self.to_s}'
                                           AND slugs_old.sluggable_id = sluggable_old.id
                                           AND slugs_new.generation_low = #{data_generation}
                                           AND slugs_old.generation_low = #{data_generation-1}
                                           AND slugs_new.sluggable_id = sluggable_new.id
                                           AND (sluggable_new.previous_id = sluggable_old.id
                                           OR  sluggable_new.id = sluggable_old.id)
                                           AND (slugs_old.sequence != slugs_new.sequence
                                                AND slugs_old.name = slugs_new.name)")
          names.each do |name|
            instances = self.find(:all, :include => :slug, :conditions => ['slugs.name = ?', name])
            instances = instances.sort_by(&:slug_sequence_in_previous_generation)
            instances.each do |instance|
              instance.slug.destroy
              instance.slug = nil
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

      # Get the sequence of the slug from the version of this model in the previous
      # data generation. If there was none, return one more than the highest sequence
      # number for models with this slug in the previous generation
      def slug_sequence_in_previous_generation
        raise "This model does not use friendly_id slugs" unless self.class.uses_friendly_id?
        if !previous_id
          previous_slug = Slug.find_in_generation(PREVIOUS_GENERATION,
                                                  :first,
                                                  :conditions => ['name = ? and sluggable_type = ?',
                                                  self.slug.name, self.class.to_s],
                                                  :order => 'sequence desc')
          if previous_slug
            return previous_slug.sequence + 1
          else
            return 1
          end
        end
        previous_slug = Slug.find_in_generation(PREVIOUS_GENERATION,
                                                :first,
                                                :conditions => ['sluggable_id = ? and sluggable_type = ?',
                                                previous_id, self.class.to_s])
        return previous_slug.sequence
      end


    end
  end
end


