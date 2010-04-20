# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#   
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Major.create(:name => 'Daley', :city => cities.first)
  transport_mode_attributes = [{ :name => 'Bus', :naptan_name => 'Bus', :active => true }, 
                               { :name => 'Coach', :naptan_name => 'Coach', :active => true }, 
                               { :name => 'Taxi', :naptan_name => 'Taxi', :active => false }, 
                               { :name => 'Air', :naptan_name => 'Air', :active => false },
                               { :name => 'Ferry', :naptan_name => 'Ferry / Ship', :active => false },
                               { :name => 'Train', :naptan_name => 'Rail', :active => true },
                               { :name => 'Metro', :naptan_name => 'Metro', :active => true },
                               { :name => 'Tram', :naptan_name => 'Tram', :active => true }]
  TransportMode.create(transport_mode_attributes)