class StaticController < ApplicationController
  
  def feedback
    if request.post?
      @feedback = Feedback.new(params[:feedback]) 
      respond_to do |format|
        format.html do
          if @feedback.valid? 
            StoryMailer.deliver_feedback(params[:feedback])
            flash[:notice] = t(:feedback_thanks)
            redirect_to(root_url)
          else
            render 'feedback'
          end
        end
        format.json do 
          @json = {}
          if @feedback.valid? 
            StoryMailer.deliver_feedback(params[:feedback])
            @json[:success] = true
          else
            @json[:success] = false
            @json[:errors] = {}
            @feedback.errors.each do |attribute,message|
              @json[:errors][attribute] = message
            end
          end
          render :json => @json
        end
      end
    end
  end
end