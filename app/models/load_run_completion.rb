class LoadRunCompletion < ActiveRecord::Base
  belongs_to :transport_mode
  belongs_to :admin_area
end