namespace :maintenance do

  desc 'Transfer routes from one operator specified as OLD_OPERATOR to another specified as NEW_OPERATOR'
  task :transfer_operator_routes_and_stations => :environment do
    unless ENV['OLD_OPERATOR'] and ENV['NEW_OPERATOR']
      usage_message "usage: rake maintenance:transfer_routes OLD_OPERATOR=old_operator_name NEW_OPERATOR=new_operator_name"
    end
    old_operator_name = ENV['OLD_OPERATOR']
    new_operator_name = ENV['NEW_OPERATOR']

    old_operators = Operator.find(:all, :conditions => ['name = ?', old_operator_name])
    new_operators = Operator.find(:all, :conditions => ['name = ?', new_operator_name])
    operator_data = {old_operator_name => old_operators, new_operator_name => new_operators}
    operator_data.each do |operator_name, operator_list|
      if operator_list.size != 1
        raise "#{operator_list.size} operators found with name #{operator_name}: Stopping."
      end
    end
    old_operator = old_operators.first
    new_operator = new_operators.first

    old_operator.route_operators.each do |route_operator|
      route = route_operator.route
      RouteOperator.create!(:operator => new_operator, :route => route)
      puts "Moving #{route.name} (destroyed route_operator association #{route_operator.id})"
      route_operator.destroy
    end
    old_operator.stop_area_operators.each do |stop_area_operator|
      stop_area = stop_area_operator.stop_area
      StopAreaOperator.create!(:operator => new_operator, :stop_area => stop_area)
      puts "Moving #{stop_area.name} (destroyed stop_area_operator association #{stop_area_operator.id})"
      stop_area_operator.destroy
    end

  end

end
