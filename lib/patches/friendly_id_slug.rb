# Patch the slug model provided by the friendly_id gem so that it has a default scope
# which hides slugs from other data generations and creates new slugs as belonging to this
# data generation

class Slug < ::ActiveRecord::Base
  default_scope :conditions => [ "#{quoted_table_name}.generation_low <= ?
                                  AND #{quoted_table_name}.generation_high >= ?",
                                  CURRENT_GENERATION, CURRENT_GENERATION ]
  before_create :set_generations

  def set_generations
    self.generation_low = CURRENT_GENERATION if self.generation_low.nil?
    self.generation_high = CURRENT_GENERATION if self.generation_high.nil?
  end

  # def set_sequence
  #   return unless new_record?
  #   klass = sluggable_type.constantize
  #   if klass.respond_to?(:versioned_by_data_generations?)
  #     if self.sluggable.previous_id
  #       similar = previous_similar_slugs_for_same_persistent_id
  #       if !similar.empty?
  #         self.sequence = similar.last.sequence
  #       end
  #     end
  #     similar = self.similar_slugs_across_all_generations
  #     self.sequence = similar.last.sequence.succ if !similar.empty?
  #     return
  #   end
  #   self.sequence = similar_slugs.last.sequence.succ if similar_to_other_slugs?
  # end
  #
  # def self.similar_slugs_across_all_generations(slug)
  #   similar = nil
  #   self.in_any_generation do
  #     similar = self.find(:all, :conditions => { :name  => slug.name,
  #                                                :scope => slug.scope,
  #                                                :sluggable_type => slug.sluggable_type },
  #                               :order => 'sequence asc' )
  #
  #   end
  #   return similar
  # end
  #
  # def self.previous_similar_slugs_for_same_persistent_id(slug)
  #   klass = slug.sluggable_type.constantize
  #   sluggable = slug.sluggable
  #   sluggable_ids = []
  #   klass.in_any_generation do
  #     sluggable_ids = klass.find(:all,
  #                                :select => 'id',
  #                                :conditions => ['persistent_id = ?', sluggable.persistent_id]).map(&:id)
  #   end
  #   if sluggable_ids.empty?
  #     return []
  #   end
  #   previous_similar = []
  #   self.in_any_generation do
  #     previous_similar = self.find(:all, :conditions => { :name => slug.name,
  #                                                         :scope => slug.scope,
  #                                                         :sluggable_type => slug.sluggable_type,
  #                                                         :sluggable_id => sluggable_ids },
  #                                        :order => "generation_high asc, created_at asc")
  #   end
  #   return previous_similar
  # end

  # Perform a block of code ignoring data generations
  def self.in_any_generation(&block)
    self.with_exclusive_scope do
      yield
    end
  end

end