class StaticController < ApplicationController
  
  def feedback
    @feedback = Feedback.new
    if request.post?
      @feedback = Feedback.new(params[:feedback]) 
      respond_to do |format|
        format.html do
          if @feedback.valid? 
            ProblemMailer.deliver_feedback(params[:feedback])
            flash[:notice] = t(:feedback_thanks)
            redirect_to(root_url)
          else
            render 'feedback'
          end
        end
        format.json do 
          @json = {}
          if @feedback.valid? 
            ProblemMailer.deliver_feedback(params[:feedback])
            @json[:success] = true
          else
            @json[:success] = false
            add_json_errors(@feedback, @json)
          end
          render :json => @json
        end
      end
    end
  end
end