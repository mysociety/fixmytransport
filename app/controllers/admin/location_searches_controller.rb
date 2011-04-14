class Admin::LocationSearchesController < Admin::AdminController
  
  def index
    @searches = LocationSearch.find(:all, :order => 'created_at desc')
  end
  
  def show
    @search = LocationSearch.find(params[:id])
  end
end
