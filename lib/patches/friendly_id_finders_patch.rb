# This patch allows the default scope applied to the Slug model to be used when finding models by
# their friendly id

module FriendlyId
  module ActiveRecordAdapter
    module Finders

      class Find

        def find_one_with_slug
          name, seq = id.to_s.parse_friendly_id
          scope = scoped(:joins => :slugs, :conditions => {:slugs => {:name => name, :sequence => seq}})
          scope = scope.scoped(:conditions => {:slugs => {:scope => scope_val}}) if fc.scope?
          # This is the patch - apply the slug's own scope to the existing scopes
          slug_scope = Slug.send(:scope, :find)
          if slug_scope
            scope = scope.scoped(slug_scope)
          end
          # End of patch
          options[:readonly] = false unless options[:readonly]
          @result = scope.first(options)
          assign_status
        end

      end
    end
  end
end