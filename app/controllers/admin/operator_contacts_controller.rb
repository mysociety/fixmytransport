class Admin::OperatorContactsController < Admin::AdminController

  before_filter :require_can_admin_organizations

  def show
    @operator_contact = OperatorContact.find(params[:id])
  end

  def new
    @operator = Operator.find_by_id(params[:operator_id])
    @operator_contact = OperatorContact.new(:operator_persistent_id => @operator.persistent_id)
  end

  def create
    @operator_contact = OperatorContact.new(params[:operator_contact])
    # don't set location type without location id
    if @operator_contact.location_persistent_id.blank? && ! @operator_contact.location_type.blank?
      @operator_contact.location_type = nil
    end
    if @operator_contact.save
      flash[:notice] = t('admin.operator_contact_created')
      redirect_to(admin_url(admin_operator_contact_path(@operator_contact)))
    else
      @operator = Operator.current.find_by_persistent_id(params[:operator_contact][:operator_persistent_id])
      render :new
    end
  end

  def update
    @operator_contact = OperatorContact.find(params[:id])
    # don't set the stop_area_id unless it has a value
    if params[:operator_contact][:stop_area_persistent_id].blank?
      params[:operator_contact].delete(:stop_area_persistent_id)
    end
    if @operator_contact.update_attributes(params[:operator_contact])
      flash[:notice] = t('admin.operator_contact_updated')
      redirect_to admin_url(admin_operator_contact_path(@operator_contact))
    else
      flash[:error] = t('admin.operator_contact_problem')
      render :show
    end
  end

end