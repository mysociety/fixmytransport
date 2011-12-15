class Admin::AdminController < ApplicationController
  protect_from_forgery
  layout "admin"
  skip_before_filter :require_beta_password
  before_filter :require_admin_user

  private

  # Record the fact that any version changes are due to actions taken in the admin interface, so they can
  # be identified and displayed
  def info_for_paper_trail
    { :admin_action => true }
  end

  # Add a notice to the flash on removal of an association of an operator with a location
  # giving a table of problems at the location that list the operator as responsible
  def add_responsibilities_notice(model_key, association_key, location_type, id_key, model)
    if params[model_key] && params[model_key][association_key]
      association_attributes = params[model_key][association_key]
      problems = []
      association_attributes.each do |key, data_hash|
        if data_hash[:_destroy] == "1"
          # are we removing from the operator end of the association, or the location end?
          if id_key == :operator_id
            problems += Operator.problems_at_location(location_type, model.id, data_hash[id_key].to_i)
          else
            problems += Operator.problems_at_location(location_type, data_hash[id_key].to_i, model.id)
          end
        end
      end
      flash[:notice] += render_to_string :partial => "admin/shared/responsibilities",
                                         :locals => { :problems => problems,
                                                      :model => model_key }
    end
  end

  # Admin sessions use a key to distinguish them from regular sessions
  def current_user_session(refresh=false)
    return @current_user_session if (defined?(@current_user_session) && ! refresh)
    @current_user_session = AdminUserSession.find(:admin)
  end

  def current_user(refresh=false)
    return @current_user if (defined?(@current_user) && ! refresh)
    @current_user = current_user_session(refresh) && current_user_session.record.user
  end

  # Admin actions should require an admin user
  def require_admin_user
    unless current_user
      if controller_name == 'user_sessions'
        redirect = nil
      else
        redirect = request.request_uri
      end
      redirect_to admin_url(admin_login_path(:redirect => redirect))
      return false
    end
    if current_user.suspended?
      flash[:error] = t('shared.suspended.forbidden')
      current_user_session.destroy
      redirect_to root_url
      return false
    end
  end

  def require_can_admin_users
    return require_admin_right(:users)
  end

  def require_can_admin_locations
    return require_admin_right(:locations)
  end

  def require_can_admin_organizations
    return require_admin_right(:organizations)
  end

  def require_can_admin_issues
    return require_admin_right(:issues)
  end

  def require_admin_right(admin_right)
    unless current_user.can_admin?(admin_right) == true
      flash[:error] = t('admin.no_permission')
      redirect_to admin_url(admin_root_path)
      return false
    end
    return true
  end

end