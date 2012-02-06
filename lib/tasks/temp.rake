namespace :temp do
  
  desc 'Update campaign slugs that end in a trailing hyphen' 
  task :update_trailing_hyphen_slugs => :environment do 
  
    Campaign.visible.each do |campaign|
      if campaign.to_param.last == '-'
        campaign.save
      end
    end
    
  end
  
  
  desc 'Transfer NXEA routes to Greater Anglia'
  task :transfer_nxea_routes_to_greater_anglia => :environment do 
    operator = Operator.find_by_name('National Express East Anglia')
    new_operator = Operator.find_by_name('Greater Anglia')
    raise "Couldn't find NXEA" unless operator
    operator.route_operators.each do |route_operator|
      route = route_operator.route
      StopAreaOperator.create!(:operator => new_operator, :route => route)
      puts route_operator.id
      route_operator.destroy
    end
    operator.stop_area_operators.each do |stop_area_operator|
      stop_area = stop_area_operator.stop_area
      StopAreaOperator.create!(:operator => new_operator, :stop_area => stop_area)
      puts stop_area_operator.id
      stop_area_operator.destroy
    end
  end 
  
end
