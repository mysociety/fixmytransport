class JourneyPattern < ActiveRecord::Base
  belongs_to :route
  has_many :route_segments, :order => 'segment_order asc'
  has_paper_trail
end