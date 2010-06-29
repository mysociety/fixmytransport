require 'spec_helper'

describe Admin::OperatorsController do

  describe 'GET #new' do 
    
    def make_request
      get :new 
    end
  
    it 'should ask for a new operator' do 
      operator = mock_model(Operator)
      Operator.should_receive(:new).and_return(operator)
      make_request
    end
  
  end
  
  describe 'GET #index' do 
  
    it 'should ask for all operators in name order paginated by default' do
      Operator.should_receive(:paginate).with(:page => nil, 
                                              :conditions => [''],
                                              :order => 'name ASC')
      get :index
    end
    
    it 'should ask for operators with part of the name or short name matching the query' do 
      Operator.should_receive(:paginate).with(:page => nil, 
                                              :conditions => ['(lower(name) like ? OR lower(short_name) like ?)',
                                              '%%something%%', '%%something%%'],
                                              :order => 'name ASC')
      
      get :index, :query => 'Something'
    end
    
    it 'should ask for operators with part of the name or short name or the whole id matching the query if it is numeric' do 
      query_string = '(lower(name) like ? OR lower(short_name) like ? OR id = ?)'
      Operator.should_receive(:paginate).with(:page => nil, 
                                              :conditions => [query_string,
                                              '%%23%%', '%%23%%', 23],
                                              :order => 'name ASC')
      
      get :index, :query => '23'
    end
    
      it 'should ask for operators by page' do 
        Operator.should_receive(:paginate).with(:page => '3', 
                                             :conditions => [''], 
                                             :order => 'name ASC')
        get :index, :page => '3'
      end
  end
  
end