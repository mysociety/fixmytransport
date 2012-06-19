class Admin::PteContactsController < Admin::AdminController

  before_filter :require_can_admin_organizations

  def show
    @pte_contact = PassengerTransportExecutiveContact.find(params[:id])
  end

  def new
    @pte = PassengerTransportExecutive.find_by_id(params[:pte_id])
    @pte_contact = PassengerTransportExecutiveContact.new(:passenger_transport_executive_persistent_id => @pte.persistent_id)
  end

  def create
    @pte_contact = PassengerTransportExecutiveContact.new(params[:pte_contact])
    if @pte_contact.save
      flash[:notice] = t('admin.pte_contact_created')
      redirect_to(admin_url(admin_pte_contact_path(@pte_contact)))
    else
      @pte = PassengerTransportExecutive.find_by_persistent_id(params[:pte_contact][:passenger_transport_executive_persistent_id])
      render :new
    end
  end

  def update
    @pte_contact = PassengerTransportExecutiveContact.find(params[:id])
    if @pte_contact.update_attributes(params[:pte_contact])
      flash[:notice] = t('admin.pte_contact_updated')
      redirect_to admin_url(admin_pte_contact_path(@pte_contact))
    else
      flash[:error] = t('admin.pte_contact_problem')
      render :show
    end
  end

end