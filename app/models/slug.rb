# This model extends the slug model provided by the friendly_id gem to add some specific functionality
# in support of data generations - see lib/fixmytransport/data_generations.rb. Specifically,
# the slug model has a default scope which hides slugs from other data generations in normal operation,
# and creates new slugs as belonging to this data generation. The sequence on the slug of a new model
# is made consistent with that of any previous models sharing its persistent id. New models do not reuse
# slugs from previous generations

class Slug < AbstractSlug

  puts "in app/models"
  default_scope :conditions => [ "#{quoted_table_name}.generation_low <= ?
                                  AND #{quoted_table_name}.generation_high >= ?",
                                  CURRENT_GENERATION, CURRENT_GENERATION ]
  before_create :set_generations

  def set_generations
    puts "setting generations"
    self.generation_low = CURRENT_GENERATION if self.generation_low.nil?
    self.generation_high = CURRENT_GENERATION if self.generation_high.nil?
  end

  # Extension of the friendly_id set_sequence method - will set the sequence of a new  slug
  # associated with an instance of a model versioned by data generations to the same as the
  # sequence of the most recent previous instance with the same sluggable model persistent
  # id, name and scope.
  def set_sequence
    puts "setting sequence"
    return unless new_record?
    klass = self.sluggable_type.constantize
    if klass.respond_to?(:versioned_by_data_generations?)
      similar = self.class.previous_similar_slugs_for_same_persistent_id(self)
      if !similar.empty?
        self.sequence = similar.last.sequence
        return
      end
      similar = self.class.similar_slugs_across_all_generations(self)
      self.sequence = similar.last.sequence.succ if !similar.empty?
      return
    end
    self.sequence = similar_slugs.last.sequence.succ if similar_to_other_slugs?
  end

  # Finds similar slugs by name, scope and sluggable type across data generations
  def self.similar_slugs_across_all_generations(slug)
    puts "similar slugs"
    similar = nil
    self.in_any_generation do
      similar = self.find(:all, :conditions => { :name  => slug.name,
                                                 :scope => slug.scope,
                                                 :sluggable_type => slug.sluggable_type },
                                :order => 'sequence asc' )
    end
    return similar
  end

  # Finds similar slugs by name, scope and sluggable type across data generations that
  # are associated with the same persistent id as the slug passed.
  def self.previous_similar_slugs_for_same_persistent_id(slug)
    puts "previous similar slugs"
    klass = slug.sluggable_type.constantize
    sluggable = slug.sluggable
    sluggable_ids = klass.find(:all,
                               :select => 'id',
                               :conditions => ['persistent_id = ?', sluggable.persistent_id]).map(&:id)
    return [] if sluggable_ids.empty?
    previous_similar = []
    self.in_any_generation do
      previous_similar = self.find(:all, :conditions => { :name => slug.name,
                                                          :scope => slug.scope,
                                                          :sluggable_type => slug.sluggable_type,
                                                          :sluggable_id => sluggable_ids },
                                         :order => "generation_high asc, created_at asc")
    end
    return previous_similar
  end

  # Perform a block of code ignoring data generations
  def self.in_any_generation(&block)
    self.with_exclusive_scope do
      yield
    end
  end

end