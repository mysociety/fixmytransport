class StopAreaOperator < ActiveRecord::Base
  belongs_to :operator
  belongs_to :stop_area
end
