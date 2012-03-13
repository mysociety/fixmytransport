class Admin::ProblemsController < Admin::AdminController

  helper_method :sort_column, :sort_direction
  before_filter :require_can_admin_issues

  def show
    @problem = Problem.find(params[:id])
  end

  def index
    conditions = []
    query_clauses = []
    if params[:query]
      query = params[:query].downcase
      query_clause = "(lower(subject) like ?"
      conditions << "%%#{query}%%"
      # numeric?
      if query.to_i.to_s == query
        query_clause += " OR id = ?"
        conditions << query.to_i
      end
      query_clause += ")"
      query_clauses << query_clause
    end
    conditions = [query_clauses.join(" AND ")] + conditions
    @problems = Problem.paginate :page => params[:page],
                                 :conditions => conditions,
                                 :include => :reporter,
                                 :order => "#{sort_column} #{sort_direction}"
  end

  def resend
    @problem = Problem.find(params[:id])
    responsibility = @problem.responsibilities.find(params[:responsibility_id])
    sent_emails = ProblemMailer.send_report(@problem, [responsibility.organization], [])
    if @problem.campaign
      # Not creating this campaign event on the campaign.campaign_events association.
      # Passing a campaign_id param instead in order to avoid triggering a bug in calling
      # #hash on paperclip attachments in paperclip 2.3.11 - #hash is called by #to_yaml which is called
      # the quote method on models to be inserted into queries
      CampaignEvent.create!(:event_type => 'problem_report_resent',
                            :campaign_id => @problem.campaign_id,
                            :data => { :user_id => user_for_edits.id,
                            :sent_emails => sent_emails.map{ |sent_email| sent_email.id } })
    end
    flash[:notice] = t('admin.problem_resent')
    redirect_to admin_url(admin_problem_path(@problem.id))
  end

  def update
    @problem = Problem.find(params[:id])
    # filter params for responsibilities without organization ids - from the blank form fields
    params[:problem][:responsibilities_attributes].each do |key, value_hash|
      if value_hash[:id].blank? && value_hash[:organization_id].blank?
        params[:problem][:responsibilities_attributes].delete(key)
      end
    end
    if !params[:problem][:status_code].nil?
      @problem.status_code = params[:problem][:status_code]
    end
    success = false
    ActiveRecord::Base.transaction do
      success = (@problem.update_attributes(params[:problem]) && @problem.update_assignments)
    end
    if success
      flash[:notice] = t('admin.problem_updated')
      redirect_to admin_url(admin_problem_path(@problem.id))
    else
      flash[:error] = t('admin.problem_problem')
      render :show
    end
  end

  def sort_column
    columns = Problem.column_names + ["users.name"]
    columns.include?(params[:sort]) ? params[:sort] : "id"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
  end

end
