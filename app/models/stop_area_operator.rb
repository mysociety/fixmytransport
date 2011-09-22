class StopAreaOperator < ActiveRecord::Base
  belongs_to :operator
  belongs_to :stop_area
  # virtual attribute used for adding new stop area operators
  attr_accessor :_add
 
end
