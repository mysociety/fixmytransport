# == Schema Information
# Schema version: 20100707152350
#
# Table name: stop_areas
#
#  id                       :integer         not null, primary key
#  code                     :string(255)
#  name                     :text
#  administrative_area_code :string(255)
#  area_type                :string(255)
#  grid_type                :string(255)
#  easting                  :float
#  northing                 :float
#  creation_datetime        :datetime
#  modification_datetime    :datetime
#  revision_number          :integer
#  modification             :string(255)
#  status                   :string(255)
#  created_at               :datetime
#  updated_at               :datetime
#  coords                   :geometry
#  lon                      :float
#  lat                      :float
#  locality_id              :integer
#  loaded                   :boolean
#

require 'spec_helper'

describe StopArea do
  before(:each) do
    @valid_attributes = {
      :code => "value for code",
      :name => "value for name",
      :administrative_area_code => "value for administrative_area_code",
      :area_type => "value for area_type",
      :grid_type => "value for grid_type",
      :easting => 1.5,
      :northing => 1.5,
      :creation_datetime => Time.now,
      :modification_datetime => Time.now,
      :revision_number => 1,
      :modification => "value for modification",
      :status => "ACT"
    }
  end

  it "should create a new instance given valid attributes" do
    stop_area = StopArea.new(@valid_attributes)
    stop_area.valid?.should be_true
  end

  describe 'when loading' do

    before do
      @stop_area = StopArea.new(@valid_attributes)
      @stop_area.loaded = false
    end

    it 'should not require locality' do
      @stop_area.locality_id = nil
      @stop_area.valid?.should be_true
    end

  end

  describe 'when loaded' do

    before do
      @stop_area = StopArea.new(@valid_attributes)
      @stop_area.loaded = true
    end

  end

  describe ' area ' do

    fixtures default_fixtures

    describe 'for stop areas whose stops all share a locality' do

      it 'should return the locality_name' do
        stop_areas(:victoria_station_leaf).area.should == "Victoria"
      end

    end

    describe 'for areas whose stops do not share a locality' do

      it 'should return nil' do
        stop_areas(:victoria_station_root).area.should be_nil
      end

    end

  end

  describe ' description ' do

    describe 'for stop areas with an area attribute' do

      before do
        @stop_area = StopArea.new(:name => 'London Victoria Rail Station')
        @stop_area.stub!(:area).and_return('Victoria')
      end

      it 'should be of the form "name in area" ' do
        @stop_area.description.should == "London Victoria Rail Station in Victoria"
      end

    end

  end

  describe 'when asked for a Passenger Transport Executive' do

    before do
      @tfl = mock_model(PassengerTransportExecutive)
      PassengerTransportExecutive.stub!(:find_by_name).with('Transport for London').and_return(@tfl)
      MySociety::MaPit.stub!(:call).and_return({ 44 => {'name' => 'A council'}})
    end

    describe 'if its name ends with "Underground Station" and type is "GTMU"' do

      it 'should return TfL' do
        @stop_area = StopArea.new(:name => 'Epping Underground Station', :area_type => 'GTMU')
        @stop_area.passenger_transport_executive.should == @tfl
      end

    end

  end

  describe 'when asked for responsible organizations' do

    describe 'if it is not a train station' do

      before do
        @stop_area = StopArea.new
        @stop_area.stub!(:transport_mode_names).and_return(['Bus'])
        @operator = mock_model(Operator)
      end

      describe 'when there are operators' do

        before do
          @stop_area.stub!(:operators).and_return([@operator])
        end

        it 'should return the operators' do
          @stop_area.responsible_organizations.should == [@operator]
        end

      end

      describe 'when there are no operators' do

        before do
          @stop_area.stub!(:operators).and_return([])
        end

        describe 'when there is a PTE' do

          before do
            @pte = mock_model(PassengerTransportExecutive)
            @stop_area.stub!(:passenger_transport_executive).and_return(@pte)
          end

          it 'should return the PTE' do
            @stop_area.responsible_organizations.should == [@pte]
          end

        end

        describe 'when there is no PTE' do

          before do
            @stop_area.stub!(:passenger_transport_executive).and_return(nil)
            @council = mock("council")
            @stop_area.stub!(:councils).and_return([@council])
          end

          it 'should return the council' do
            @stop_area.responsible_organizations.should == [@council]
          end

        end

      end

    end

    describe 'if it is a train station' do

      before do
        @mock_operator = mock_model(Operator)
        @stop_area = StopArea.new
        @stop_area.stub!(:transport_mode_names).and_return(['Train'])
      end

      describe 'when there are operators' do

        before do
          @stop_area.stub!(:operators).and_return([@mock_operator])
        end

        it 'should return the operators' do
          @stop_area.responsible_organizations.should == [@mock_operator]
        end

      end

      describe 'when there are no operators' do

        before do
          @stop_area.stub!(:operators).and_return([])
        end

        it 'should return an empty list' do
          @stop_area.responsible_organizations.should == []
        end

      end

    end




    describe 'if it is a ferry terminal' do

      before do

        @stop_area = StopArea.new
        @stop_area.stub!(:transport_mode_names).and_return(['Ferry'])
      end

      describe 'if there are operators' do

        before do
          @operator = mock_model(Operator)
          @stop_area.stub!(:operators).and_return([@operator])
        end

        it 'should return the operators' do
          @stop_area.responsible_organizations.should == [@operator]
        end

      end

      describe 'if there are no operators' do

        before do
          @pte = mock_model(PassengerTransportExecutive)
          @stop_area.stub!(:operators).and_return([])
          @stop_area.stub!(:passenger_transport_executive).and_return(@pte)
        end

        it 'should return any PTE' do
          @stop_area.responsible_organizations.should == [@pte]
        end

      end

      describe 'if there are no operators and no PTE' do

        before do
          @council = mock_model(Council)
          @stop_area.stub!(:operators).and_return([])
          @stop_area.stub!(:passenger_transport_executive).and_return(nil)
          @stop_area.stub!(:councils).and_return([@council])
        end

        it 'should return the council' do
          @stop_area.responsible_organizations.should == [@council]
        end

      end

    end

  end

  describe 'as a transport location' do

    before do
      @instance = StopArea.new
    end

    it_should_behave_like 'a transport location'

  end

  describe 'when mapping a list of stop areas to common areas' do

    fixtures default_fixtures

    it 'should return a list that does not include any member of the original list whose ancestor is also in the list' do
      stop_list = [stop_areas(:victoria_station_leaf), stop_areas(:victoria_station_root)]
      StopArea.map_to_common_areas(stop_list).should == [stop_areas(:victoria_station_root)]
    end

  end
  
  describe 'when giving a readable type' do 
    
    it 'should return "station" for a train stop area' do 
      stop_area = StopArea.new(:area_type => 'GRLS')
      stop_area.stub!(:transport_mode_names).and_return(['Train'])
      stop_area.readable_type.should == 'station'
    end
  
    it 'should return "station" for a metro/tram stop area' do 
      stop_area = StopArea.new(:area_type => 'GTMU')
      stop_area.stub!(:transport_mode_names).and_return(['Tram/Metro'])
      stop_area.readable_type.should == 'station'
    end 
    
    it 'should return "terminal" for a ferry stop area' do
      stop_area = StopArea.new(:area_type => 'GTFS')
      stop_area.stub!(:transport_mode_names).and_return(['Ferry'])
      stop_area.readable_type.should == 'terminal'
    end
    
   it 'should return "stop area" for a stop area' do 
     stop_area = StopArea.new(:area_type => 'GBCS')
     stop_area.stub!(:transport_mode_names).and_return(['Bus', 'Coach', 'Tram/Metro'])
     stop_area.readable_type.should == 'bus/coach station'
   end
  
  end
  
  describe 'when searching for nearest stop areas' do        
      
    it 'should return a list of stop_areas' do 
      expected_conditions = ["ST_Distance(ST_Transform(ST_GeomFromText('POINT(0.084 51.497)', 4326),27700),coords) < ?", 100000]
      expected_order = "ST_Distance(ST_Transform(ST_GeomFromText('POINT(0.084 51.497)', 4326),27700),coords) asc"
      StopArea.should_receive(:find).with(:all, { :conditions=> expected_conditions,
                                                  :order=> expected_order, 
                                                  :limit=>1 }).and_return([])
      stop_area_list = StopArea.find_nearest(0.084, 51.497)
    end
    
    it 'shoud fail with invalid (lon,lat)' do
      expect { StopArea.find_nearest(0.01, 'foo') }.should raise_error
    end
  
  end
end
