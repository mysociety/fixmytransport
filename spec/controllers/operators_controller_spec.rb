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
  
end