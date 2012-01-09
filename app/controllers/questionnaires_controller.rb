class QuestionnairesController < ApplicationController
  
  def show
    @questionnaire = Questionnaire.find_by_token(params[:email_token])
    if !@questionnaire
      flash[:error] = t('questionnaires.show.could_not_find_questionnaire')
      redirect_to root_url
      return
    end
    if @questionnaire.completed_at
      flash[:error] = t('questionnaires.show.questionnaire_completed', 
                         :feedback_url => feedback_url,
                         :issue_url => @template.issue_url(@questionnaire.subject))
      redirect_to root_url
      return
    end
    session = UserSession.login_by_confirmation(@questionnaire.user)     
    if ! session
      flash[:error] = t('questionnaires.show.forbidden')
      redirect_to root_url
      return
    end 
    # make sure the current user is set as we've just created or changed the user session
    current_user(refresh=true)
    @errors = {}
  
    setup_template_variables
  end
  
  private
  
  # set up the variables needed to display the questionnaire 
  def setup_template_variables
    if @questionnaire.subject.is_a?(Problem)
      @problem = @questionnaire.subject
      map_params_from_location(@questionnaire.subject.location.points, 
                               find_other_locations=false)
    else
      @campaign = @questionnaire.subject
      map_params_from_location(@questionnaire.subject.location.points, 
                               find_other_locations=false,
                               height=CAMPAIGN_PAGE_MAP_HEIGHT,
                               width=CAMPAIGN_PAGE_MAP_WIDTH)
      @collapse_quotes = params[:unfold] ? false : true
    end
  end
  
end