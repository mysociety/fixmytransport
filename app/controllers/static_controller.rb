class StaticController < ApplicationController
  
  def feedback
  if request.post?
    @feedback = Feedback.new(params[:feedback]) 
    if @feedback.valid? 
        StoryMailer.deliver_feedback(params[:feedback])
        flash[:notice] = t(:feedback_thanks)
        redirect_to(root_url)
      else
        render 'feedback'
      end
    end
  else
    @feedback = Feedback.new
  end
end