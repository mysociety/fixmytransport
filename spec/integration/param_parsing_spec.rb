require 'spec_helper'

describe "parameter parsing" do

  class TestController < ActionController::Base
    class << self
      attr_accessor :last_request_parameters, :last_request_type
    end

    def parse
      self.class.last_request_parameters = request.request_parameters
      head :ok
    end
  end

  before do
    @controller.stub!(:app_status).and_return('live')
  end

  it "should parse parameters with quotes correctly" do
    query = "text%5D=First+sentence.%0D%0A%0D%0A%22Second+sentence.%22"
    expected = {"text" => "First sentence.\r\n\r\n\"Second sentence.\""}
    assert_parses expected, query
  end

  it 'should parse parameters without equals correctly' do
    assert_parses({"action" => {"foo" => nil}}, "action[foo]")
  end

  it '' do
    assert_parses({"action" => {"foo" => { "bar" => nil }}}, "action[foo][bar]")
  end

  it '' do
    assert_parses({"action" => {"foo" => { "bar" => nil }}}, "action[foo][bar][]")
  end

  it '' do
    assert_parses({"action" => {"foo" => nil}}, "action[foo][]")
  end

  it '' do
    assert_parses({"action"=>{"foo"=>[{"bar"=>nil}]}}, "action[foo][][bar]")
  end

  after do
    TestController.last_request_parameters = nil
  end

  def with_test_routing
    with_routing do |set|
      set.draw do |map|
        map.connect ':action', :controller => "test"
      end
      yield
    end
  end

  def assert_parses(expected, actual)
    with_test_routing do
      post "parse", actual
      assert_response :ok
      assert_equal(expected, TestController.last_request_parameters)
    end
  end
end
