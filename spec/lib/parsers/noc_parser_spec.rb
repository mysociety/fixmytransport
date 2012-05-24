require 'spec_helper'

describe Parsers::NocParser do

  def example_file filename
    File.join(RAILS_ROOT, 'spec', 'examples', 'NOC', filename)
  end

  describe 'when cleaning operator codes' do

    before do
      @parser = Parsers::NocParser.new
    end

    it 'should remove a leading "*"' do
      @parser.clean_operator_code("*NX").should == 'NX'
    end

    it 'should remove a leading "="' do
      @parser.clean_operator_code("=MW").should == 'MW'
    end

  end

  describe 'when parsing an example CSV file of operator data for operator codes' do

    before(:each) do
      @parser = Parsers::NocParser.new
      mock_wm_region = mock_model(Region, :name => 'West Midlands')
      mock_em_region = mock_model(Region, :name => 'East Midlands')
      @current_generation = mock('current generation')
      Region.stub!(:current).and_return(@current_generation)
      @current_generation.stub!(:find_by_code).and_return(mock_em_region)
      @current_generation.stub!(:find_by_code).with('WM').and_return(mock_wm_region)
      @operator = mock_model(Operator)
      @current_generation = mock('current generation')
      Operator.stub!(:current).and_return(@current_generation)
      @current_generation.stub!(:find_by_noc_code).and_return(@operator)
      @operator_codes = []
      @parser.parse_operator_codes(example_file("operators.tsv")) do |operator_code|
        @operator_codes << operator_code
      end
    end

    it 'should create operator_code models for each populated region code field' do
      @operator_codes.first.region.name.should == 'West Midlands'
      @operator_codes.first.code.should == 'AMG'
      @operator_codes.first.operator.should == @operator
    end

    it 'should create an operator_code model for the MDV field, if populated, for each of the MDV regions' do
      @operator_codes.second.region.name.should == 'East Midlands'
      @operator_codes.second.code.should == 'AMF'
      @operator_codes.second.operator.should == @operator
    end

  end

  describe 'when parsing an example CSV file of operator data for vosa licenses' do

    before(:each) do
      @parser = Parsers::NocParser.new
      @operator = mock_model(Operator)
      Operator.stub!(:find_by_noc_code).and_return(@operator)
      @vosa_licenses = []
      @parser.parse_vosa_licenses(example_file("operators.tsv")) do |vosa_license|
        @vosa_licenses << vosa_license
      end
    end

    it 'should create vosa_license models for each populated VOSA license field' do
      @vosa_licenses.size.should == 1
      @vosa_licenses.first.number.should == 'PD0001892'
    end

  end

  describe 'when parsing an example CSV file of operator data for operators' do

    before(:each) do
      @parser = Parsers::NocParser.new
      @mock_transport_mode = mock_model(TransportMode, :name => 'Train')
      Operator.stub!(:vehicle_mode_to_transport_mode).and_return(@mock_transport_mode)
      @operators = []
      @parser.parse_operators(example_file("operators.tsv")){ |operator| @operators << operator }
    end

    it 'should extract the NOC code' do
      @operators.first.noc_code.should == "AMGR"
    end

    it 'should extract the name' do
      @operators.first.name.should == 'A & M Group'
    end

    it 'should extract the reference name' do
      @operators.first.reference_name.should == 'Ref'
    end

    it 'should extract the VOSA license name' do
      @operators.first.vosa_license_name.should == 'SPANGAP LTD'
    end

    it 'should extract the parent' do
      @operators.first.parent.should == 'Parent'
    end

    it 'should extract the ultimate parent' do
      @operators.first.ultimate_parent.should == 'Ultimate parent'
    end

    it 'should extract the vehicle mode' do
      @operators.first.vehicle_mode.should == 'Bus'
    end

    it 'should set the transport mode' do
      @operators.first.transport_mode.name.should == 'Train'
    end

  end

end
