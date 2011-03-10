class JourneyPattern < ActiveRecord::Base
  belongs_to :route
  has_many :route_segments, :order => 'segment_order asc'
  has_paper_trail

  def identical_segments?(other)
    route_segments.all? do |route_segment|
      other.route_segments.detect do |other_segment|
        other_segment.from_stop == route_segment.from_stop &&
        other_segment.to_stop == route_segment.to_stop &&
        other_segment.from_terminus == route_segment.from_terminus &&
        other_segment.to_terminus == route_segment.to_terminus &&
        other_segment.segment_order == route_segment.segment_order
      end
    end
  end

end