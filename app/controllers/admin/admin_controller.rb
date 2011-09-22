class Admin::AdminController < ApplicationController
  protect_from_forgery
  layout "admin" 
  skip_before_filter :require_beta_password
  
  private
  
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
  
end