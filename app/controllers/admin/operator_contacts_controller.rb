class Admin::OperatorContactsController < ApplicationController
  
  layout "admin" 
  
  def show 
    @operator_contact = OperatorContact.find(params[:id])
  end
  
  def new
    @operator = Operator.find_by_id(params[:operator_id])
    @operator_contact = OperatorContact.new(:operator_id => params[:operator_id])
  end
  
  def create 
    @operator_contact = OperatorContact.new(params[:operator_contact])
    if @operator_contact.save
      flash[:notice] = t(:operator_contact_created)
      redirect_to(admin_url(admin_operator_contact_path(@operator_contact)))
    else
      @operator = Operator.find_by_id(params[:operator_contact][:operator_id])
      render :new
    end
  end
  
  def update
    @operator_contact = OperatorContact.find(params[:id])
    if @operator_contact.update_attributes(params[:operator_contact])
      flash[:notice] = t(:operator_contact_updated)
      redirect_to admin_url(admin_operator_contact_path(@operator_contact))
    else
      flash[:error] = t(:operator_contact_problem)
      render :show
    end
  end
  
end