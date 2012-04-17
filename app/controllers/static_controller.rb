class StaticController < ApplicationController
  
  def feedback
    @title = t('static.feedback.title')
    @email = MySociety::Config.get('CONTACT_EMAIL', 'contact@localhost')
    allowed_types = ['Route', 'SubRoute']
    if params[:location_id] and params[:location_type]
      @location = instantiate_location(params[:location_id], params[:location_type])
    end
    if params[:operator_id]
      @operator = Operator.find(:first, :conditions => ['id = ?', params[:operator_id]])
    end
    @feedback = Feedback.new
    if request.post?
      @feedback = Feedback.new(params[:feedback]) 
      if @feedback.valid? 
        ProblemMailer.deliver_feedback(params[:feedback], @location, @operator)
        flash[:notice] = t('static.feedback.feedback_thanks')
        redirect_to(root_url)
      else
        render 'feedback'
      end
    end
  end

  def about
    @title = t("static.about.about_this_site")
  end
  
  # probably won't end up living in the static_controller, but for now it's a home
  def facebook
    @body_class = "facebook-canvas"
    render :template => 'static/facebook', :layout => 'facebook'
    # NB max width for canvas should be 760px
    # process incoming request_ids here (if any): test code for this has been deleted
  end

  def guide_index
    @guides = Guide.find(:all, :order => :title)
  end

  def show_guide
    @guide = Guide.find(params[:guide])
    @title = @guide.title
    @all_guides = Guide.find(:all, :order => :title)
    @example_issues = @guide.problems + @guide.campaigns
  end

end
