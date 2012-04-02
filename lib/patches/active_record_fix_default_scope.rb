module ActiveRecord
  class Base
    class << self
      # The following methods fix issues with eager loading (Preloading) & default_scope 
      # The method construct_finder_sql_with_included_association is new, and deals with cases
      # where associations with their own scopes are referenced in the conditions of a query. 
      # The other methods are taken from unapproved Rails 2.3.x ticket: 
      # https://rails.lighthouseapp.com/projects/8994/tickets/2931-find-with-include-ignores-default_scope
      private
      
      def construct_finder_sql_with_included_associations(options, join_dependency)
        scope = scope(:find)
        sql = "SELECT #{column_aliases(join_dependency)} FROM #{(scope && scope[:from]) || options[:from] || quoted_table_name} "
        sql << join_dependency.join_associations.collect{|join| join.association_join }.join

        add_joins!(sql, options[:joins], scope)
        add_conditions!(sql, options[:conditions], scope)
        
        # This is the patch - when including associations, include any conditions from 
        # the current scope of the associated class (and if its a through reflection, 
        # from the current scope of the through reflection)
        join_dependency.reflections.each do |reflection|
          reflection_options = reflection.options
          find_scope = reflection.klass.scope(:find)
          if find_scope
            sql << "#{condition_word(sql)} #{merge_conditions(find_scope[:conditions])}" 
          end
          if reflection_options[:through]
            through_reflection = reflection.through_reflection
            through_find_scope = through_reflection.klass.scope(:find)
            if through_find_scope
              sql << "#{condition_word(sql)} #{merge_conditions(through_find_scope[:conditions])}"
            end
          end
        end
        # End of patch
        
        add_limited_ids_condition!(sql, options, join_dependency) if !using_limitable_reflections?(join_dependency.reflections) && ((scope && scope[:limit]) || options[:limit])

        add_group!(sql, options[:group], options[:having], scope)
        add_order!(sql, options[:order], scope)
        add_limit!(sql, options, scope) if using_limitable_reflections?(join_dependency.reflections)
        add_lock!(sql, options, scope)

        return sanitize_sql(sql)
      end

      def preload_belongs_to_association(records, reflection, preload_options={})
        return if records.first.send("loaded_#{reflection.name}?")
        options = reflection.options
        primary_key_name = reflection.primary_key_name

        if options[:polymorphic]
          polymorph_type = options[:foreign_type]
          klasses_and_ids = {}

          # Construct a mapping from klass to a list of ids to load and a mapping of those ids back to their parent_records
          records.each do |record|
            if klass = record.send(polymorph_type)
              klass_id = record.send(primary_key_name)
              if klass_id
                id_map = klasses_and_ids[klass] ||= {}
                id_list_for_klass_id = (id_map[klass_id.to_s] ||= [])
                id_list_for_klass_id << record
              end
            end
          end
          klasses_and_ids = klasses_and_ids.to_a
        else
          id_map = {}
          records.each do |record|
            key = record.send(primary_key_name)
            if key
              mapped_records = (id_map[key.to_s] ||= [])
              mapped_records << record
            end
          end
          klasses_and_ids = [[reflection.klass.name, id_map]]
        end

        klasses_and_ids.each do |klass_and_id|
          klass_name, id_map = *klass_and_id
          next if id_map.empty?
          klass = klass_name.constantize

          table_name = klass.quoted_table_name
          primary_key = reflection.options[:primary_key] || klass.primary_key
          column_type = klass.columns.detect{|c| c.name == primary_key}.type
          ids = id_map.keys.map do |id|
            if column_type == :integer
              id.to_i
            elsif column_type == :float
              id.to_f
            else
              id
            end
          end
          conditions = "#{table_name}.#{connection.quote_column_name(primary_key)} #{in_or_equals_for_ids(ids)}"
          conditions << append_conditions(reflection, preload_options)
          find_options = { :conditions => [conditions, ids], :include => options[:include],
                           :select => options[:select], :joins => options[:joins], :order => options[:order] }

          associated_records = klass.send(klass == self ? :with_exclusive_scope : :with_scope, :find => find_options) { klass.all }
          set_association_single_records(id_map, reflection.name, associated_records, primary_key)
        end
      end

      def find_associated_records(ids, reflection, preload_options)
        options = reflection.options
        table_name = reflection.klass.quoted_table_name

        if interface = reflection.options[:as]
          parent_type = if reflection.active_record.abstract_class?
            self.base_class.sti_name
          else
            reflection.active_record.sti_name
          end

          conditions = "#{reflection.klass.quoted_table_name}.#{connection.quote_column_name "#{interface}_id"} #{in_or_equals_for_ids(ids)} and #{reflection.klass.quoted_table_name}.#{connection.quote_column_name "#{interface}_type"} = '#{parent_type}'"
        else
          foreign_key = reflection.primary_key_name
          conditions = "#{reflection.klass.quoted_table_name}.#{foreign_key} #{in_or_equals_for_ids(ids)}"
        end

        conditions << append_conditions(reflection, preload_options)

        # This is the patch - using the associated models' current scope on the find query 
        # rather than exclusive_scope
        find_options = { :select => (preload_options[:select] || options[:select] || "#{table_name}.*"),
                         :include => preload_options[:include] || options[:include], :conditions => [conditions, ids],
                         :joins => options[:joins], :group => preload_options[:group] || options[:group],
                         :order => preload_options[:order] || options[:order] }

        reflection.klass.send(reflection.klass == self ? :with_exclusive_scope : :with_scope, :find => find_options) { reflection.klass.all }
        # End of patch
      end

      def preload_has_and_belongs_to_many_association(records, reflection, preload_options={})
        table_name = reflection.klass.quoted_table_name
        id_to_record_map, ids = construct_id_map(records)
        records.each {|record| record.send(reflection.name).loaded}
        options = reflection.options
      
        conditions = "t0.#{reflection.primary_key_name} #{in_or_equals_for_ids(ids)}"
        conditions << append_conditions(reflection, preload_options)
      
        find_options = { :conditions => [conditions, ids], :include => options[:include], :order => options[:order],
                         :joins => "INNER JOIN #{connection.quote_table_name options[:join_table]} t0 ON #{reflection.klass.quoted_table_name}.#{reflection.klass.primary_key} = t0.#{reflection.association_foreign_key}",
                         :select => "#{options[:select] || table_name+'.*'}, t0.#{reflection.primary_key_name} as the_parent_record_id" }
      
        # This is the patch - using the associated models' current scope on the find query rather than exclusive scope
        associated_records = reflection.klass.send(reflection.klass == self ? :with_exclusive_scope : :with_scope, :find => find_options) { reflection.klass.all }
        # End of patch
        set_association_collection_records(id_to_record_map, reflection.name, associated_records, 'the_parent_record_id')
      end
    end
  end
end