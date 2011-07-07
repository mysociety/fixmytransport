class MergeCandidate < ActiveRecord::Base
  belongs_to :national_route, :class_name => 'Route'
  
end