def add_stops_from_list route, atco_codes
  jp = route.journey_patterns.build(:destination => 'test dest')
  atco_codes.each_cons(2) do |from_atco_code, to_atco_code|
    from_stop = get_stop(from_atco_code)
    to_stop = get_stop(to_atco_code)
    jp.route_segments << RouteSegment.new(:from_stop => from_stop, :to_stop => to_stop)
  end
end

def get_stop(atco_code)
  (Stop.find_by_atco_code(atco_code) or Stop.new(:atco_code => atco_code))
end