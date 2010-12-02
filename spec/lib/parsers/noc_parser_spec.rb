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
  
  describe 'when parsing an example CSV file of stop area data' do 
    
    before(:each) do 
      @parser = Parsers::NocParser.new
      mock_wm_region = mock_model(Region, :name => 'West Midlands')
      mock_em_region = mock_model(Region, :name => 'East Midlands')
      Region.stub!(:find_by_code).with('WM').and_return(mock_wm_region)
      Region.stub!(:find_by_code).with('EM').and_return(mock_em_region)
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
    
    it 'should create vosa_license models for each populated VOSA license field' do
      @operators.first.vosa_licenses.size.should == 1 
      @operators.first.vosa_licenses.first.number.should == 'PD0001892'
    end
    
    it 'should create operator_code models for each populated region code field' do 
      @operators.first.operator_codes.first.region.name.should == 'West Midlands'
      @operators.first.operator_codes.first.code.should == 'AMG'
    end
     
  end

end
