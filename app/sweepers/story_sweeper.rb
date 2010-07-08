class StorySweeper < ActionController::Caching::Sweeper
  observe Story

  # If our sweeper detects that a Story was updated call this
  def after_update(story)
    if story.confirmed? 
      expire_cache_for(story)
    end
  end

  private
  
  def expire_cache_for(story)
    # Expire the recent stories
    expire_fragment('recent_stories')
  end
  
end