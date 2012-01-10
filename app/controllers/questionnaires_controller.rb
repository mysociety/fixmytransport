class QuestionnairesController < ApplicationController

  before_filter :require_valid_questionnaire

  def show
    @errors = {}
    setup_template_variables
  end

  def update
    @errors = {}
    if params[:fixed].blank?
      @errors[:fixed] = t('questionnaires.show.fixed_blank')
    end
    if (params[:ever_reported].blank? && !current_user.answered_ever_reported?)
      @errors[:ever_reported] = t('questionnaires.show.reported_blank')
    end
    if (params[:fixed] == 'no' && @questionnaire.subject.status == :fixed && params[:update].blank?)
      @errors[:update] = t('questionnaires.show.please_explain')
    end
    if (['no', 'unknown'].include?(params[:fixed]) && params[:another].blank?)
      @errors[:another] = t('questionnaires.show.please_answer_another')
    end

    if ! @errors.empty?
      setup_template_variables
      render :action => 'show'
      return false
    end

    if ['yes', 'no'].include?(params[:ever_reported])
      # set the ever reported flag on the questionnaire
      if params[:ever_reported] == 'yes'
        @questionnaire.ever_reported = true
      elsif params[:ever_reported] == 'no'
        @questionnaire.ever_reported = false
      end
    end

    # set the old status code on the questionnaire
    @questionnaire.old_status_code = @questionnaire.subject.status_code

    # set the flag to send another if requested
    if params[:another] == 'yes'
      @questionnaire.subject.send_questionnaire = true
    end

    ActiveRecord::Base.transaction do
      # set the problem or campaign to the new status
      mark_closed = nil
      mark_open = nil
      if ['yes', 'no', 'unknown'].include?(params[:fixed])
        case params[:fixed]
        when 'yes'
          if @questionnaire.subject.status != @questionnaire.subject.fixed_state
            mark_fixed = true
            @questionnaire.subject.status = @questionnaire.subject.fixed_state
          end
        when 'no'
          if @questionnaire.subject.status != :confirmed
            mark_open = true
            @questionnaire.subject.status = :confirmed
          else
            @questionnaire.subject.updated_at = Time.now
          end
        end
        @questionnaire.subject.save!
      end

      # add the update
      if !params[:update].blank? or mark_open or mark_fixed
        text = params[:update].blank? ? t('questionnaires.show.user_completed_questionnaire') : params[:update]
        comment_data = { :confirmed => true,
                         :text => text,
                         :mark_fixed => mark_fixed,
                         :mark_open => mark_open,
                         :model => @questionnaire.subject }
        Comment.create_from_hash(comment_data, current_user)
      end

      # set the new status code
      @questionnaire.new_status_code = @questionnaire.subject.status_code
      @questionnaire.completed_at = Time.now
      @questionnaire.save!
    end

    # show a thanks message
    render :action => 'completed'
    return false
  end

  private

  # N.B. logs in the questionnaire user if valid questionnaire found
  def require_valid_questionnaire
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
    if !@questionnaire.subject.visible?
      flash[:error] = t('questionnaires.show.hidden')
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
  end

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