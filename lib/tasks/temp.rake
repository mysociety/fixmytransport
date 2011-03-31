namespace :temp do

  desc "Unassigns route operators for routes where the operator code comes from a region the route doesn't go through"
  task :unassign_bad_operators => :environment do
    bus = TransportMode.find_by_name('Bus')
    Route.find_each(:conditions => ['transport_mode_id = ?
                                     AND route_source_admin_areas.source_admin_area_id is null
                                     AND route_source_admin_areas.id is not null
                                     AND route_operators.operator_id is not null', bus],
                    :include => [:route_source_admin_areas, :route_operators]) do |route|
      current_route_operators = route.route_operators(true)
      print "."
      STDOUT.flush
      operators = Operator.find_all_by_nptdr_code(route.transport_mode, route.operator_code, route.region, route)
      bad_operators = current_route_operators.select{ |route_operator| !operators.include?(route_operator.operator) }
      bad_operators.each do |route_operator|
        puts "Removing operator #{route_operator.operator.name} for #{route.name} #{route.operator_code} #{route.id}"
        route_operator.destroy
      end
    end
  end
  
end
