class Admin::CouncilContactsController < Admin::AdminController
    
  def show 
    @council_contact = CouncilContact.find(params[:id])
  end
  
  def index
    if !params[:area_id].blank? 
      @council = Council.find_by_id(params[:area_id])
      render :template => 'admin/council_contacts/council_index'
      return
    end
    @councils = Council.find_all()
  end
  
  def new
    @council = Council.find_by_id(params[:area_id])
    @council_contact = CouncilContact.new(:area_id => params[:area_id])
  end
  
  def create 
    @council_contact = CouncilContact.new(params[:council_contact])
    if @council_contact.save
      flash[:notice] = t('admin.council_contact_created')
      redirect_to(admin_url(admin_council_contact_path(@council_contact.id)))
    else
      @council = Council.find_by_id(params[:council_contact][:area_id])
      render :new
    end
  end
  
  def update
    @council_contact = CouncilContact.find(params[:id])
    if @council_contact.update_attributes(params[:council_contact])
      flash[:notice] = t('admin.council_contact_updated')
      redirect_to admin_url(admin_council_contact_path(@council_contact.id))
    else
      flash[:error] = t('admin.council_contact_problem')
      render :show
    end
  end
  
end