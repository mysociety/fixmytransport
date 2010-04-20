require 'spec_helper'

describe Parsers::NptdrParser do 
  
  def example_file filename
    File.join(RAILS_ROOT, 'spec', 'examples', 'NPTDR', filename)
  end
  
  describe 'when parsing a TSV file of route data' do 
    
    before(:all) do 
      @parser = Parsers::NptdrParser.new
      @routes = []
      @parser.parse_routes(example_file("nptdr.tsv")){ |route| @routes << route }
    end
    
    it 'should extract the route number' do 
      @routes.first.number.should == '376'
    end
    
  end

end