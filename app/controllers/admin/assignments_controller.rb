class Admin::AssignmentsController < Admin::AdminController

  def show
    @assignment = Assignment.find(params[:id])
    if @assignment.problem.responsible_operators.size == 1
      @operator = @assignment.problem.responsible_operators.first
    else
      if @assignment.data[:organization_name]
        @operator = Operator.find(:first, :conditions => ['lower(name) = ?', @assignment.data[:organization_name].downcase])
      end
    end
  end

  def check
    @assignment = Assignment.find(params[:id])
    if params[:operator_id].blank?
      redirect_to admin_url(admin_assignment_path(@assignment.id))
      return false
    else  
      begin
        @operator = Operator.find(params[:operator_id])
      rescue Exception => e
        flash[:error] = e.message
        redirect_to admin_url(admin_assignment_path(@assignment.id))
        return
      end
      problem = @assignment.problem
      location = problem.location
      set_location_operator(location)
      problem.responsibilities.build( :organization_id => @operator.id,
                                      :organization_type => 'Operator' )
      location_only = @assignment.data ? @assignment.data[:location_only] : nil
      new_email = (@assignment.data && @assignment.data[:organization_email]) ? @assignment.data[:organization_email].strip : nil
      @assignment_complete = false
      # does the operator already a contact for this location?
      existing_contact = @operator.contact_for_category_and_location("Other", location, exception_on_fail=false)
      if new_email.blank?
        if existing_contact
          # no new email, but we already have one
          complete_assignment(@assignment, problem)
        else
          # no new email, no existing
          flash[:error] = I18n.translate("admin.assignment_updated_no_contact")
        end  
      else  
        @contact = nil
        if existing_contact
          if existing_contact.email.downcase != new_email
            if ! params[:override_contact]
              flash.now[:error] =  I18n.translate('admin.assignment_need_to_choose_override', :existing => existing_contact.email )
              @need_override = true
              render :action => 'show'
              return
            else
              update_contact(existing_contact, new_email, location_only)
            end
          else
            # same as existing
            @assignment_complete = true
          end
        else
          contact_params = {:email => new_email, :category => 'Other'}
          if location_only
            contact_params[:location_id] = location.id
            contact_params[:location_type] = location.class.to_s
          end
          @operator.operator_contacts.build(contact_params)
        end
      end          
      begin 
        ActiveRecord::Base.transaction do 
          @operator.save!
          problem.save!
          location.save! 
          if @contact
            @contact.save!
          end
          if @assignment_complete
            complete_assignment(@assignment, problem)
          end
          @assignment.save!
        end        
      rescue Exception => e
        flash[:error] = e.message
      end
      redirect_to admin_url(admin_assignment_path(@assignment.id))
    end
  end

  private
  
  def set_location_operator(location)
    if location.is_a?(Route)
      location.route_operators.build({:operator => @operator})
    elsif location.is_a?(StopArea)
      location.stop_area_operators.build({:operator => @operator})
    else
      raise "Unhandled location type: #{location.class.to_s}"
    end
  end

  def update_contact(existing_contact, new_email, location_only)
    if params[:override_contact] == '0'
      # keep existing
      @assignment_complete = true
    elsif params[:override_contact] == '1'
      if location_only && existing_contact.location
        existing_contact.email = new_email
        @contact = existing_contact
      elsif location_only
        @contact = @operator.operator_contacts.build(:email => new_email, 
                                                     :category => 'Other', 
                                                     :location => location)
      elsif existing_contact.location
        @contact = @operator.operator_contacts.build(:email => new_email, 
                                                     :category => 'Other')
      else
        existing_contact.email = new_email
        @contact = existing_contact
      end
      @assignment_complete = true
    end
  end

  def complete_assignment(assignment, problem)
    assignment.status = :complete
    # set operator on assignment data for write-to-organization assignment for this problem
    org_data = {:organizations => problem.organization_info(:responsible_organizations) }
    Assignment.complete_problem_assignments(problem, {'write-to-transport-organization' => org_data })
    flash[:notice] = I18n.translate("admin.assignment_updated")
  end
end