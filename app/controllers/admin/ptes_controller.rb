class Admin::PtesController < Admin::AdminController
  
  def index
    @ptes = PassengerTransportExecutive.paginate :page => params[:page], 
                                                 :order => 'name ASC'
  end

  def show
    @pte = PassengerTransportExecutive.find(params[:id])
  end
   
  def update
    @pte = PassengerTransportExecutive.find(params[:id])
    if @pte.update_attributes(params[:pte])
      flash[:notice] = t('admin.pte_updated')
      redirect_to admin_url(admin_pte_path(@pte))
    else
      flash[:error] = t('admin.pte_problem')
      render :show
    end
  end
  
end
