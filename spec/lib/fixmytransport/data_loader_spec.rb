require 'fixmytransport/data_loader'
include FixMyTransport::DataLoader

require 'spec_helper'

describe FixMyTransport::DataLoader do

  describe 'when converting a list of fields to an attribute hash to go in finders' do

    before do
    end

    it 'should convert a simple list of symbols to a hash keyed by the symbols,
        using values from the instance' do
      stop = mock_model(Stop, :atco_code => 'XXXX')
      fields_to_attribute_hash([:atco_code], stop).should == { :atco_code => 'XXXX' }
    end

    it 'should convert symbols ending in _id using associations' do
      locality = mock_model(Locality, :id => 66)
      stop = mock_model(Stop, :locality => locality)
      fields_to_attribute_hash([:locality_id], stop).should == { :locality_id => 66 }
    end

    it 'should convert references to attributes on associations correctly' do
      pending do
        stop_area = mock_model(StopArea, :persistent_id => 57, :id => 88)
        operator = mock_model(Operator, :persistent_id => 76, :id => 45)
        stop_area_operator = mock_model(StopAreaOperator, :stop_area => stop_area,
                                                          :operator => operator)
        fields =[ { :stop_area => [ :persistent_id ] },
                  { :operator => [ :persistent_id ] },
                  :stop_area_id, :operator_id ]
        expected_hash = {:stop_areas => { :persistent_id => 57 },
                         :operators => { :persistent_id => 76 },
                         :stop_area_id => 88,
                         :operator_id => 45 }
        fields_to_attribute_hash(fields, stop_area_operator).should == expected_hash
      end
    end

  end

end