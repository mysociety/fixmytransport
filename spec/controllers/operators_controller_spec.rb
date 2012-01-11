require 'spec_helper'
require 'digest'

describe OperatorsController do

  before do
    transport_mode = mock_model(TransportMode, :name => 'train')
    TransportMode.stub!(:find).and_return(transport_mode)
    @mock_operator = mock_model(Operator, 
      :name => 'Sodor & Mainland Railway',
      :transport_mode => transport_mode, 
      :to_i => 11)
    Problem.stub!(:find_recent_issues).and_return([])
  end

  describe 'GET #issues' do

    def make_request(params={})
      get :issues, params
    end

    it 'should ask for a page of recent issues' do
      Operator.should_receive(:find).with('11').and_return(@mock_operator)
      Problem.should_receive(:find_recent_issues).with(10, {:offset => 0, :single_operator => @mock_operator})
      make_request(:id => "11")
    end

  end

  describe 'GET #show' do
    
    def make_request(params={})
      get :show, params
    end

    it 'should default to showing a page of issues' do
      Operator.should_receive(:find).with('11').and_return(@mock_operator)
      Problem.should_receive(:find_recent_issues).with(10, {:offset => 0, :single_operator => @mock_operator})
      make_request(:id => "11")
      assigns[:current_tab].should == :issues
      assigns[:title].should == @mock_operator.name
      assigns[:transport_mode_and_link].should include "train services"
    end

  end

  describe 'GET #stations' do

    def make_request(params={})
      get :stations, params
    end
    
    describe 'for an operator with one stop area' do

      before do
        StopArea.stub!(:find).and_return([mock_model(StopArea, :name => "A station", :area_type => "GRLS")])
        Operator.stub!(:find).and_return(@mock_operator)
      end    
    
      it 'should display the station in a tab and not retrieve any issues' do
        StopArea.should_receive(:find)
        Problem.should_not_receive(:find_recent_issues)
        make_request(:id => "11")
        assigns[:current_tab].should == :stations        
      end

      it 'should describe the stop areas as a station' do
        make_request(:id => "11")
        assigns[:banner_text].should include "station"
        assigns[:station_type_descriptions][:short].should == "stations"
      end

      describe 'if that stop area is for ferries' do
        
        before do
          StopArea.stub!(:find).and_return([mock_model(StopArea, :name => "Some jetty", :area_type => "GFTD")])
        end
        
        it 'should describe it as a ferry terminal' do
          make_request(:id => "11")
          assigns[:banner_text].should include "ferry terminal"
          assigns[:station_type_descriptions][:short].should == "terminals"
        end
      end
      
    end

    describe 'for an operator with no stop areas' do

      before do
        StopArea.stub!(:find).and_return([])
      end    
    
      it 'should retrieve issues instead, for the issues tab' do
        Operator.should_receive(:find).with('11').and_return(@mock_operator)
        StopArea.should_receive(:find)
        Problem.should_receive(:find_recent_issues)
        make_request(:id => "11")
        assigns[:current_tab].should == :issues
        assigns[:banner_text].should include "is not responsible for any stations or terminals"
      end

    end

  end
  
end