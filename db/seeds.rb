# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)
  transport_mode_attributes = [{ :name => 'Bus', :naptan_name => 'Bus', :active => true, :route_type => 'BusRoute' }, 
                               { :name => 'Coach', :naptan_name => 'Coach', :active => true, :route_type => 'CoachRoute' }, 
                               { :name => 'Taxi', :naptan_name => 'Taxi', :active => false, :route_type => nil }, 
                               { :name => 'Air', :naptan_name => 'Air', :active => false, :route_type => nil },
                               { :name => 'Ferry', :naptan_name => 'Ferry / Ship', :active => true, :route_type => 'FerryRoute' },
                               { :name => 'Train', :naptan_name => 'Rail', :active => true, :route_type => 'TrainRoute' },
                               { :name => 'Tram/Metro', :naptan_name => 'Tram / Metro', :active => true, :route_type => 'TramMetroRoute' }]
  TransportMode.create(transport_mode_attributes)