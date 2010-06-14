require File.dirname(__FILE__) + '/abstract_unit'

class Person < ActiveRecord::BaseWithoutTable
  column :name, :string
  column :lucky_number, :integer, 4
  
  validates_presence_of :name

  attr_reader :callback_invoked
  after_save :invoke_callback

  def invoke_callback
    @callback_invoked = true
  end
end

class ActiveRecordBaseWithoutTableTest < Test::Unit::TestCase
  def test_default_value
    assert_equal 4, Person.new.lucky_number
  end

  def test_validation
    p = Person.new

    assert !p.save
    assert p.errors[:name]

    assert p.update_attributes(:name => 'Name')
  end

  def test_typecast
    assert_equal 1, Person.new(:lucky_number => "1").lucky_number
  end

  def test_callback
    callback_invoked = false
    p = Person.new :name => 'Bob'
    assert_nil p.callback_invoked, "Shouldn't invoke the callback just yet"
    p.save!
    assert p.callback_invoked, "Should have invoked the callback after the save"
  end

  def test_cached_column_variables_reset_when_column_defined
    cached_variables = %w(column_names columns_hash content_columns dynamic_methods_hash)


    Person.column_names
    Person.columns_hash
    Person.content_columns
    Person.column_methods_hash

    cached_variables.each { |v| assert_not_nil Person.instance_variable_get("@#{v}"), "Expected @#{v} to be set" }
    Person.column :new_column, :string
    cached_variables.each { |v| assert_nil Person.instance_variable_get("@#{v}"), "Expected @#{v} to be reset after altering column information" }
  end
end
