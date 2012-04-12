# Patch an issue in friendly id when updating the scope on a slugged model to a scope that already has 
# more than one slug of the same name. The sequence for the updated slug needs to be set to one more than
# the last similar slug when ordered by sequence, not the first.
module FriendlyId
  module ActiveRecordAdapter
    module SluggedModel
      
      private
      
      def update_scope
        return unless slug && scope_changed?
        self.class.transaction do
          slug.scope = send(friendly_id_config.scope).to_param
          similar = Slug.similar_to(slug)
          puts similar.inspect
          if !similar.empty?
            # This is the changed line - last in the array, not first
            slug.sequence = similar.last.sequence.succ
          end
          slug.save!
        end
      end
    end
  end
end