namespace :pte do 
  
  desc 'Load Passenger Transport Executive and associations to area ids'
  task :load => :environment do 
    
    pte_area_names_to_mapit_area_ids = {}

    ptes = { 'Greater Manchester' => ['GMPTE', 'http://en.wikipedia.org/wiki/Greater_Manchester_Passenger_Transport_Executive'],	
             'Merseyside'         => ['Merseytravel', 'http://en.wikipedia.org/wiki/Merseyside_Passenger_Transport_Executive'],	
             'South Yorkshire'    => ['Travel South Yorkshire', 'http://en.wikipedia.org/wiki/South_Yorkshire_Passenger_Transport_Executive'],	
             'Tyne and Wear'      => ['Nexus', 'http://en.wikipedia.org/wiki/Tyne_and_Wear_Passenger_Transport_Executive'],
             'West Midlands'      => ['Centro',	'http://en.wikipedia.org/wiki/West_Midlands_Passenger_Transport_Executive'],
             'West Yorkshire'     => ['Metro', 'http://en.wikipedia.org/wiki/West_Yorkshire_Passenger_Transport_Executive'],
             'Greater London'     => ['Transport for London', 'http://en.wikipedia.org/wiki/Transport_for_London'],
             'Strathclyde'        => ['SPT', 'http://en.wikipedia.org/wiki/Strathclyde_Partnership_for_Transport']
    }
    
    ptes.keys.each do |area_name|
      pte_area_names_to_mapit_area_ids[area_name] = []
    end

    metropolitan_county_to_district_names = 
      { 'Greater Manchester' => ["Manchester", "Bolton", "Bury", "Oldham", "Rochdale", "Salford", "Stockport", "Tameside", "Trafford", "Wigan"],
        'Merseyside'         => ["Liverpool", "Knowsley", "St Helens", "Sefton", "Wirral"],
        'South Yorkshire'    => ["Sheffield", "Barnsley", "Doncaster", "Rotherham"],
        'Tyne and Wear'      => ["Newcastle upon Tyne", "Gateshead", "South Tyneside", "North Tyneside", "Sunderland"],	
        'West Midlands'      => ["Birmingham", "Coventry", "Dudley", "Sandwell", "Solihull", "Walsall", "Wolverhampton"],	
        'West Yorkshire'     => ["Leeds", "Bradford", "Calderdale", "Kirklees", "Wakefield"] }
    
    spt_councils = [ 'Argyll and Bute Council',
                     'East Ayrshire Council',
                     'East Dunbartonshire Council',   
                     'East Renfrewshire Council',  
                     'Glasgow City Council', 
                     'Inverclyde Council', 
                     'North Ayrshire Council', 
                     'North Lanarkshire Council', 
                     'Renfrewshire Council', 
                     'South Ayrshire Council', 
                     'South Lanarkshire Council', 
                     'West Dunbartonshire Council' ]
                     
    # create a hash of district to county name
    districts_to_metropolitan_counties = {}
    metropolitan_county_to_district_names.each do |county, districts|
      districts.each do |district|
        raise if districts_to_metropolitan_counties[district]
        districts_to_metropolitan_counties[district] = county
      end
    end
    
    # get all the metropolitan districts, map them to area ids
    metropolitan_districts = MySociety::MaPit.call('areas', "MTD")
    metropolitan_districts.each do |area_id, area_info|
      name = area_info['name']
      name_without_council = name.gsub(/ (Borough|City) Council/, '')
      county = districts_to_metropolitan_counties[name_without_council]
      pte_area_names_to_mapit_area_ids[county] << [area_id, name]
    end
    
     
    # get all the London boroughs
    london_boroughs = MySociety::MaPit.call('areas', 'LBO')
    london_boroughs.each do |area_id, area_info|
      name = area_info['name']
      pte_area_names_to_mapit_area_ids['Greater London'] << [area_id, name]
    end
    
    # SPT
    unitary_authorities =  MySociety::MaPit.call('areas', 'UTA')
    unitary_authorities_by_name = {}
    unitary_authorities.each do |area_id, area_info|
      unitary_authorities_by_name[area_info['name']] = area_info
    end
    
    spt_councils.each do |council_name|
      area_id = unitary_authorities_by_name[council_name]['id']
      
      pte_area_names_to_mapit_area_ids['Strathclyde'] << [area_id, council_name]
    end
    
    ptes.each do |area_name, pte_info|
      pte_name, pte_wikipedia_link = pte_info
      # create a new PTE 
      pte = PassengerTransportExecutive.create(:name => pte_name, :wikipedia_url => pte_wikipedia_link)
      puts "Adding PTE #{pte_name}"
      # create the area associations
      pte_area_names_to_mapit_area_ids[area_name].each do |area_id, area_name|
        puts "Adding #{area_name} to areas covered by #{pte_name}"
        PassengerTransportExecutiveArea.create(:passenger_transport_executive_id => pte.id, :area_id => area_id)
      end
    end
        
  end

end