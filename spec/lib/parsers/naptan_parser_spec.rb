require 'spec_helper'
describe Parsers::NaptanParser do 

  describe 'when parsing an example CSV file of stop data' do 
  
    before(:all) do 
      @parser = Parsers::NaptanParser.new
      @stops = []
      @parser.parse_stops("#{RAILS_ROOT}/spec/examples/NaPTAN/Stops.csv"){ |stop| @stops << stop }
    end
    
    it 'should extract the atco codes' do 
      @stops.first.atco_code.should == '01000053203'
      @stops.second.atco_code.should == '01000053204'
    end
    
    it 'should extract the status' do 
      @stops.first.status.should == 'act'
      @stops.second.status.should == 'act'
    end
    
  end

end
