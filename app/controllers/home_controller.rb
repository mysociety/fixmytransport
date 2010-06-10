class HomeController < ApplicationController

  def index
    @story = Story.new()
    @stories = Story.find_recent(5)
  end
  
end
