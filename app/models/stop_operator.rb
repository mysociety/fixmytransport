class StopOperator < ActiveRecord::Base
  belongs_to :operator
  belongs_to :stop
  has_paper_trail
end
