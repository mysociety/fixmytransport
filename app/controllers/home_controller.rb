class HomeController < ApplicationController

  def index
    @story = Problem.new()
    @stories = Problem.find_recent(5)
  end
  
end
