# == Schema Information
# Schema version: 20100707152350
#
# Table name: stops
#
#  id                       :integer         not null, primary key
#  atco_code                :string(255)
#  naptan_code              :string(255)
#  plate_code               :string(255)
#  common_name              :text
#  short_common_name        :text
#  landmark                 :text
#  street                   :text
#  crossing                 :text
#  indicator                :text
#  bearing                  :string(255)
#  town                     :string(255)
#  suburb                   :string(255)
#  locality_centre          :boolean
#  grid_type                :string(255)
#  easting                  :float
#  northing                 :float
#  lon                      :float
#  lat                      :float
#  stop_type                :string(255)
#  bus_stop_type            :string(255)
#  administrative_area_code :string(255)
#  creation_datetime        :datetime
#  modification_datetime    :datetime
#  revision_number          :integer
#  modification             :string(255)
#  status                   :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  coords                   :geometry
#  locality_id              :integer
#  cached_slug              :string(255)
#  loaded                   :boolean
#

require 'spec_helper'

describe Stop do

  before do
    @model_type = Stop
    @valid_attributes = { :atco_code => 'a test atco_code',
                          :other_code => 'a test other code' }
    @default_attrs = { :common_name => 'A test stop',
                       :status => 'ACT',
                       :stop_type => 'BCT' }
    @expected_identity_hash = { :atco_code => 'a test atco_code' }
    @expected_temporary_identity_hash = { :other_code => 'a test other code' }
  end

  it_should_behave_like "a model that exists in data generations"

  it_should_behave_like "a model that exists in data generations and has slugs"

  describe 'when creating' do

    before(:each) do
       @valid_attributes = {
         :atco_code => "value for atco_code",
         :naptan_code => "value for naptan_code",
         :plate_code => "value for plate_code",
         :common_name => "value for common_name",
         :short_common_name => "value for short_common_name",
         :landmark => "value for landmark",
         :street => "value for street",
         :crossing => "value for crossing",
         :indicator => "value for indicator",
         :bearing => "value for bearing",
         :town => "value for town",
         :suburb => "value for suburb",
         :locality_centre => false,
         :grid_type => "value for grid_type",
         :easting => 1.5,
         :northing => 1.5,
         :lon => 1.5,
         :lat => 1.5,
         :stop_type => "value for stop_type",
         :bus_stop_type => "value for bus_stop_type",
         :administrative_area_code => "value for administrative_area_code",
         :creation_datetime => Time.now,
         :modification_datetime => Time.now,
         :revision_number => 1,
         :modification => "value for modification",
         :status => "ACT"
       }
    end

    it "should create a new instance given valid attributes" do
     stop = Stop.new(@valid_attributes)
     stop.valid?.should == true
    end

    describe 'when validating' do

      fixtures default_fixtures

      before do
        @stop = Stop.new(@valid_attributes)
      end

      it 'should be invalid if it has an atco code already used in this generation' do
        @stop.atco_code = stops(:victoria_station_one).atco_code
        @stop.valid?.should == false
      end

      it 'should be valid if it has an atco code already used in a previous generation' do
        atco_code = '9100VICTRIP'
        previous_stop = nil
        Stop.in_generation(PREVIOUS_GENERATION) do
          previous_stop = Stop.find(:first, :conditions => ['atco_code = ?', atco_code])
        end
        previous_stop.should_not == nil
        @stop.atco_code = previous_stop.atco_code
        @stop.valid?.should == true
      end

    end

  end

  describe 'when the lon/lat attributes have been changed' do 
    
    it 'should update the coords and the easting/northing' do 
      stop = Stop.new
      stop.should_receive(:coords=)
      stop.lat = 51.49526
      stop.lon = -0.14455
      stop.update_coords
      stop.easting.should == 528901.0
      stop.northing.should == 179000.0
    end
    
  end

  describe 'when finding by ATCO code' do

    fixtures default_fixtures

    it 'should ignore case' do
      Stop.find_by_atco_code('9100VICTric').should == stops(:victoria_station_one)
    end

    it 'should return nil if the code passed is blank' do
      Stop.stub!(:find).and_return(mock_model(Stop))
      Stop.find_by_atco_code('').should be_nil
    end

  end

  describe 'when finding by code' do

    it 'should return nil if the code passed is blank' do
      Stop.stub!(:find).and_return(mock_model(Stop))
      Stop.find_by_code('').should be_nil
    end

  end

  describe 'when finding by name and coordinates' do

    fixtures default_fixtures

    it 'should only return a stop whose name matches and whose coordinates are less than the specified distance away from the given stop' do
      stop = Stop.find_by_name_and_coords('Haywards Heath Rail Station', 533030, 124583, 10)
      stop.should == stops(:haywards_heath_station_interchange)
      stop = Stop.find_by_name_and_coords('Haywards Heath Rail Station', 533030, 124594, 10)
      stop.should be_nil
    end

  end

  describe 'when finding a common area' do

    fixtures default_fixtures

    it 'should return a common root stop area that all stops in the list belong to' do
      stops = [stops(:victoria_station_one), stops(:victoria_station_two)]
      Stop.common_area(stops, 6).should == stop_areas(:victoria_station_root)
    end

    it 'should not return a stop area that not all stops in the list belong to' do
       stops = [stops(:gatwick_airport_station), stops(:victoria_station_one)]
       Stop.common_area(stops, 6).should_not == stop_areas(:victoria_station_root)
    end

  end

  describe 'when giving a root stop area' do

    fixtures default_fixtures

    it 'should return the parent stop area if there are more than one' do
      stops(:victoria_station_one).root_stop_area('GRLS').should == stop_areas(:victoria_station_root)
      stops(:victoria_station_two).root_stop_area('GRLS').should == stop_areas(:victoria_station_root)
    end

  end

  describe 'when giving name without suffix' do

    before do
      @train_mode = mock_model(TransportMode, :name => 'Train')
      @tram_mode = mock_model(TransportMode, :name => 'Tram/Metro')
    end

    it 'should remove "Rail Station" from the end of a train station name' do
      Stop.new(:common_name => "Kensington Rail Station").name_without_suffix(@train_mode).should == "Kensington"
    end

    it 'should remove "Underground Station" from the end of the name' do
      Stop.new(:common_name => "Kensington Underground Station").name_without_suffix(@tram_mode).should == "Kensington"
    end

  end

  describe 'when asked for councils' do

    before do
      @stop = Stop.new(:lat => 100.1, :lon => 200.2)
      MySociety::MaPit.stub!(:call).and_return({ "33" =>
                                                 { "id" =>  "33",
                                                   "name" => "A test area" },
                                                 "55" =>
                                                 { "id" => "55",
                                                   "name" => "Another test area"} })
      @council_types = ["DIS", "LBO", "MTD", "UTA", "LGD", "CTY", "COI"]
    end

    it 'should send a request to MaPit' do
      MySociety::MaPit.should_receive(:call).with('point', '4326/200.200000,100.100000', :type => @council_types)
      @stop.councils
    end

    it 'should format a very small float lat or lon value to non-scientific format' do
      @stop.lat = 0.000004
      MySociety::MaPit.should_receive(:call).with('point', '4326/200.200000,0.000004', :type => @council_types)
      @stop.councils
    end

    it 'should memoize the value of the response' do
      MySociety::VotingArea.should_receive(:va_council_parent_types).at_most(:once)
      2.times { @stop.councils }
    end

    it 'should create an array of council models from the returned data' do
      councils = @stop.councils
      councils.is_a?(Array).should be_true
      councils.size.should == 2
      councils.all?{ |council| council.class.to_s == 'Council' }.should == true
      councils.any?{ |council| council.name == "A test area" }.should == true
      councils.any?{ |council| council.name == 'Another test area' }.should == true
    end

    describe 'when the MaPit request returns an error sym' do

      before do
        MySociety::MaPit.stub!(:call).and_return(:service_unavailable)
      end

      it 'should raise an exception' do
        lambda{ @stop.councils }.should raise_exception('Council lookup service unavailable')
      end

    end

    describe 'if a council returned has sole responsibility for transport' do

      before do
        MySociety::MaPit.stub!(:call).and_return({'2233' => { "country_name"=>"England",
                                                              "name"=>"Norfolk County Council",
                                                              "id"=>2233,
                                                              "type"=>"CTY",
                                                              "type_name"=>"County council" },
                                                  '2388' => { "country_name"=>"England",
                                                              "name"=>"South Norfolk District Council",
                                                              "country"=>"E",
                                                              "id"=>2388,
                                                              "type"=>"DIS",
                                                              "type_name"=>"District council" }})
        sr = mock_model(SoleResponsibility, :council_id => 2233)
        SoleResponsibility.stub!(:find).with(:all).and_return([sr])
        @stop = Stop.new(:lat => 100.1, :lon => 200.2)
      end

      it 'should only return that council' do
        @stop.councils.size.should == 1
        @stop.councils.first.name.should == 'Norfolk County Council'
      end

    end

  end

  describe 'when asked for responsible organizations' do

    before do
      @stop = Stop.new
    end

    describe 'when the transport mode is not train' do

      before do
        @stop.stub!(:transport_mode_names).and_return(['Bus', 'Coach'])
      end

      describe 'if there are operators' do

        before do
          @operator = mock_model(Operator)
          @stop.stub!(:operators).and_return([@operator])
        end

        it 'should return the operators ' do
          @stop.responsible_organizations.should == [@operator]
        end

      end

      describe 'if there are no operators' do

        before do
          @stop.stub!(:operators).and_return([])
        end

        it 'should return the PTE if there is one' do
          mock_pte = mock_model(PassengerTransportExecutive)
          @stop.stub!(:passenger_transport_executive).and_return(mock_pte)
          @stop.responsible_organizations.should == [mock_pte]
        end

        it 'should return the councils if there is no PTE' do
          mock_council = mock_model(Council)
          @stop.stub!(:passenger_transport_executive).and_return(nil)
          @stop.stub!(:councils).and_return([mock_council])
          @stop.responsible_organizations.should == [mock_council]
        end

      end

    end
  end

  describe 'when asked if a PTE is responsible' do

    it 'should return false if the responsible organization is a council' do
      stop = Stop.new
      stop.stub!(:responsible_organizations).and_return(Council.from_hash('id' => 33, :name => 'A test council'))
      stop.stub!(:passenger_transport_executive).and_return(nil)
      stop.pte_responsible?.should == false
    end

  end

  describe 'as a transport location' do

    before do
      @instance = Stop.new
    end

    it_should_behave_like 'a transport location'

  end

  describe 'when finding the nearest stop to a set of National Grid coordinates' do
    
    before do 
      @easting = 444
      @northing = 333
    end 
  
    it 'should exclude an id passed in the exclude_id parameter from the search conditions' do
      Stop.should_receive(:find).with(:first, :order => anything(),
                                              :conditions => ["id != ?", 55]) 
      Stop.find_nearest(@easting, @northing, exclude_id=55)
    end
    
    it 'should include any extra conditions passed in the search conditions' do 
      Stop.should_receive(:find).with(:first, :order => anything(), 
                                              :conditions => ['lat is not null'])
      Stop.find_nearest(@easting, @northing, exclude_id=nil, extra_conditions="lat is not null")
    end
  
    it 'should combine exclude_id and extra conditions if both are passed' do 
      Stop.should_receive(:find).with(:first, :order => anything(),
                                              :conditions => ['id != ? AND lat is not null', 55])
      Stop.find_nearest(@easting, @northing, exclude_id=55, extra_conditions="lat is not null")
    end
  
  end
  
  describe 'when asked for a PTE' do

    it 'should return one if there is one that covers one of the relevant councils' do
      mock_pte = mock_model(PassengerTransportExecutive)
      mock_pte_area = mock_model(PassengerTransportExecutiveArea, :pte => mock_pte)
      PassengerTransportExecutiveArea.stub!(:find_by_area_id).with(33).and_return(mock_pte_area)
      stop = Stop.new
      stop.stub!(:councils).and_return([mock('Council', :id => 33)])
      stop.passenger_transport_executive.should == mock_pte
    end

  end

end

