class QuestionnairesController < ApplicationController

  before_filter :require_valid_questionnaire, :only => [:show, :update]
  before_filter :require_valid_issue, :only => [:creator_fixed]

  def show
    @errors = {}
    setup_template_variables(@questionnaire.subject)
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
      setup_template_variables(@questionnaire.subject)
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
    if params[:another] == 'yes' && ['no', 'unknown'].include?(params[:fixed])
      @questionnaire.subject.send_questionnaire = true
    end

    ActiveRecord::Base.transaction do
      # set the problem or campaign to the new status
      mark_closed = nil
      mark_open = nil
      if ['yes', 'no', 'unknown'].include?(params[:fixed])
        case params[:fixed]
        when 'yes'
          if @questionnaire.subject.status != :fixed
            mark_fixed = true
            @questionnaire.subject.status = :fixed
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
    if params[:fixed] == 'yes'
      render :action => 'completed'
      return false
    else
      if params[:fixed] == 'no'
        if @questionnaire.subject.is_a?(Problem)
          location = @questionnaire.subject.location
          if location.campaigns.visible.count > 0
            existing_problems_path = existing_problems_path(:location_id => location.id,
                                                            :location_type => location.class.to_s,
                                                            :source => 'questionnaire')
            flash[:large_notice] = t('questionnaires.completed.next_steps_problem_existing_campaigns',
                                     :url => existing_problems_path,
                                     :location => @template.at_the_location(location))
          else
            new_problem_path = new_problem_path(:location_id => location.id,
                                                :location_type => location.class.to_s,
                                                :reference_id => @questionnaire.subject.id)
            flash[:large_notice] = t('questionnaires.completed.next_steps_problem',
                                     :url => new_problem_path,
                                     :orgs => @questionnaire.subject.responsible_org_descriptor())
          end
        else
          flash[:large_notice] = t('questionnaires.completed.next_steps_campaign')
        end
      else
        flash[:large_notice] = t('questionnaires.completed.please_come_back')
      end
      redirect_to(@template.issue_url(@questionnaire.subject))
      return false
    end
  end

  # Ask the "have you ever reported an issue before" question when the user marks an issue
  # as fixed (not in response to a questionnaire)
  def creator_fixed
    @errors = {}
    if request.post?
      if !['yes', 'no'].include?(params[:ever_reported])
        setup_template_variables(@issue)
        @errors[:ever_reported] = t('questionnaires.show.reported_blank')
        render :action => 'creator_fixed'
        return
      end
      ever_reported = (params[:ever_reported] == 'yes') ? true : false
      @questionnaire = Questionnaire.create!(:subject => @issue,
                                             :user => current_user,
                                             :old_status_code => flash[:old_status_code],
                                             :new_status_code => @issue.status_code,
                                             :completed_at => Time.now,
                                             :sent_at => Time.now,
                                             :ever_reported => ever_reported)
      render :template => 'questionnaires/completed'
      return
    end
    setup_template_variables(@issue)
  end

  private

  def require_valid_issue
    if params[:id].blank? || !['Campaign', 'Problem'].include?(params[:type])
      flash[:error] = t('questionnaires.creator_fixed.issue_not_found')
      redirect_to root_url
      return
    end
    @issue = params[:type].constantize.find(params[:id])
    # user not associated with issue
    user_field = @issue.is_a?(Problem) ? :reporter : :initiator
    if current_user.nil? || current_user != @issue.send(user_field)
      flash[:error] = t('questionnaires.creator_fixed.issue_not_found')
      redirect_to root_url
      return
    end
    # set a flag that we don't want to redirect here on logout
    @no_redirect_on_logout = true
  end

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
    # set a flag that we don't want to redirect here on logout
    @no_redirect_on_logout = true
  end

  # set up the variables needed to display the questionnaire
  def setup_template_variables(issue)
    if issue.is_a?(Problem)
      @map_height = LOCATION_PAGE_MAP_HEIGHT
      @map_width = LOCATION_PAGE_MAP_WIDTH
      @problem = issue
    else
      @map_height = CAMPAIGN_PAGE_MAP_HEIGHT
      @map_width = CAMPAIGN_PAGE_MAP_WIDTH
      @campaign = issue
      @collapse_quotes = params[:unfold] ? false : true
    end
    map_params_from_location(issue.location.points,
                             find_other_locations=false,
                             height=@map_height,
                             width=@map_width)
  end

end