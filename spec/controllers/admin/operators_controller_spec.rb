require 'spec_helper'

describe Admin::OperatorsController do

  describe 'GET #new' do

    before do
      @required_admin_permission = :organizations
    end

    def make_request
      get :new
    end

    it_should_behave_like "an action that requires a specific admin permission"

    it 'should ask for a new operator' do
      operator = mock_model(Operator)
      Operator.should_receive(:new).and_return(operator)
      make_request
    end

  end

  describe 'GET #index' do

    before do
      @required_admin_permission = :organizations
      @default_params = {}
    end

    def make_request(params=@default_params)
      get :index, params
    end

    it_should_behave_like "an action that requires a specific admin permission"


    it 'should ask for all operators in name order paginated by default' do
      Operator.should_receive(:paginate).with(:page => nil,
                                              :conditions => [''],
                                              :order => 'name ASC')
      make_request
    end

    it 'should ask for operators with part of the name or short name or the whole code matching the query' do
      query_string = '(lower(name) like ? OR lower(short_name) like ? OR lower(code) = ?)'
      Operator.should_receive(:paginate).with(:page => nil,
                                              :conditions => [query_string,
                                              '%%something%%', '%%something%%', 'something'],
                                              :order => 'name ASC')

      make_request(:query => 'Something')
    end

    it 'should ask for operators with part of the name or short name or the whole code or id matching the query if it is numeric' do
      query_string = '(lower(name) like ? OR lower(short_name) like ? OR lower(code) = ? OR id = ?)'
      Operator.should_receive(:paginate).with(:page => nil,
                                              :conditions => [query_string,
                                              '%%23%%', '%%23%%', '23', 23],
                                              :order => 'name ASC')

      make_request(:query => '23')
    end

      it 'should ask for operators by page' do
        Operator.should_receive(:paginate).with(:page => '3',
                                             :conditions => [''],
                                             :order => 'name ASC')
        make_request(:page => '3')
      end
  end

end