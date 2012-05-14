require 'spec_helper'
require 'digest'
require 'nokogiri'

describe OperatorsController do

  before do
    @transport_mode = mock_model(TransportMode, :name => 'train')
    TransportMode.stub!(:find).and_return(@transport_mode)
    @mock_operator = mock_model(Operator,
      :name => 'Sodor & Mainland Railway',
      :transport_mode => @transport_mode,
      :to_i => 11,
      :stop_areas => [],
      :routes => [],
      :problem_count => 0,
      :campaign_count => 0)
    Problem.stub!(:find_recent_issues).and_return([])
  end

  describe 'GET #index' do

    before do
      @mock_operator_z = mock_model(Operator,
        :name => 'Zebra Trains Ltd',
        :transport_mode => @transport_mode,
        :to_i => 11)

      Operator.stub!(:find).and_return([@mock_operator, @mock_operator_z])
      Operator.stub!(:all_by_letter).and_return({@mock_operator.name[0].chr.upcase => Array.new(22, @mock_operator),
                                                 @mock_operator_z.name[0].chr.upcase => [@mock_operator_z]})
      Operator.stub!(:count).and_return(30)
    end

    def make_request(params={})
      get :index, params
    end

    it 'should ask for a list of all operators' do
      Operator.should_receive(:all_by_letter)
      make_request
      assigns[:operator_initial_chars].should == ['S', 'Z']
    end

    describe 'when sent with an initial letter' do

      describe 'if there are many results' do
        it 'should use the initial letter (tab) if there are any operators beginning with that letter' do
          make_request(:initial_char => 'z')
          assigns[:initial_char].should == 'Z'
        end

        it 'should switch the initial letter (tab) to the first one that matches if there are no operators beginning with that letter' do
          make_request(:initial_char => 'x')
          assigns[:initial_char].should == 'S'
        end
      end

      describe 'if there are only a few results' do

        before do
          Operator.stub!(:all_by_letter).and_return({@mock_operator.name[0].chr.upcase => [@mock_operator]})
          Operator.stub!(:count).and_return(1)
        end

        it 'should discard the initial letter (because all results are shown without being broken down by initial)' do
          make_request(:initial_char => 'x')
          assigns[:initial_char].should == nil
        end
      end

    end

    describe 'when searching' do

      it 'should search with conditions if a query param is supplied' do
        Operator.should_receive(:find).with(:all, {:conditions=>["(lower(name) like ? OR lower(short_name) like ?)", "%%needle%%", "%%needle%%"]})
        make_request(:query => 'NEEDLE')
        assigns[:search_query].should == 'needle'
      end
    end

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

    before do
      @model_type = Operator
      @default_params = { :id => 'train-operator' }
    end


    def make_request(params=@default_params)
      get :show, params
    end

    it_should_behave_like "a show action that falls back to a previous generation and redirects"

    it "should load operator's issues (because the default tab displayed on the operator's page is Issues)" do
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

      it 'should not retrieve any issues because the issues tab is not being displayed' do
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

      it 'should retrieve issues instead, because the issues tab is displayed instead' do
        Operator.should_receive(:find).with('11').and_return(@mock_operator)
        StopArea.should_receive(:find)
        Problem.should_receive(:find_recent_issues)
        make_request(:id => "11")
        assigns[:current_tab].should == :issues
        assigns[:banner_text].should include "is not responsible for any stations or terminals"
      end

    end

  end

  # FIXME: integrate_views is here to force views to be rendered,
  # solely so that we can check that valid XML is generated when the
  # Atom feed is requested.  Really this should be done in functional
  # test, but currently the project is lacking those.

  integrate_views

  describe 'GET #issues [atom]' do

    def make_request(params={})
      get :issues, params
    end

    it 'should ask for all issues' do
      Operator.should_receive(:find).with('11').and_return(@mock_operator)
      Problem.should_receive(:find_recent_issues).with(false, {:single_operator => @mock_operator})
      make_request(:id => "11", :format => "atom")
      assigns[:issues].length.should == 0
    end

    it 'should return valid XML' do
      Operator.should_receive(:find).with('11').and_return(@mock_operator)
      make_request(:id => "11", :format => "atom")
      Nokogiri::XML(response.body) { |config|
        config.options = Nokogiri::XML::ParseOptions::STRICT
      }
    end

  end

end
