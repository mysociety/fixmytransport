require 'activerecord-diff'
require 'test/unit'

require 'pry'

class Person < ActiveRecord::Base
  include ActiveRecord::Diff
end

ActiveRecord::Base.establish_connection('adapter' => 'sqlite3', 'database' => ':memory:')

ActiveRecord::Schema.define do
  create_table :people do |table|
    table.column :name, :string
    table.column :email_address, :string
  end
end

Person.create :name => 'alice', :email_address => 'alice@example.org'

Person.create :name => 'bob', :email_address => 'bob@example.org'
Person.create :name => 'BOB', :email_address => 'BOB@EXAMPLE.ORG'

Person.create :name => 'eve', :email_address => 'bob@example.org'


class TestCase < Test::Unit::TestCase
  def setup
    @people = Person.find(:all)

    @alice, @bob, @capital_bob, @eve = *@people
  end

  def keysort(hash)
    hash.sort_by { |k, v| k.to_s }
  end

  def assert_diff(a, b, diff)
    assert_equal keysort(diff), keysort(a.diff(b))
  end

  def test_diff_query
    @people.each do |person|
      @people.each do |other_person|
        if other_person == person
          assert_equal false, person.diff?(other_person)
        else
          assert person.diff?(other_person)
        end
      end
    end
  end

  def test_diff_against_other_record
    assert_diff @bob, @alice, {:name => %w( bob alice ), :email_address => %w( bob@example.org alice@example.org )}

    assert_diff @bob, @eve, {:name => %w( bob eve )}
  end

  def test_diff_with_block
    assert_diff @bob, @capital_bob, {:name => %w( bob BOB), :email_address => %w( bob@example.org BOB@EXAMPLE.ORG )}
    
    diff = @bob.diff(@capital_bob) do |attrib, old, new|
      [attrib, old.downcase, new.downcase]
    end

    assert diff.empty?
  end


  def test_diff_against_saved_self
    assert ! @eve.diff?

    @eve.name = 'alice'

    assert @eve.diff?

    assert_diff @eve, nil, {:name => ['eve', 'alice']}
  end

  def test_diff_against_hash
    assert_diff @bob, {:name => 'joe'}, {:name => ['bob', 'joe']}
  end

  def test_inclusion_and_exclusion
    Person.diff :include => [:id], :exclude => [:email_address]

    assert_diff @alice, @bob, {:id => [1, 2], :name => %w( alice bob )}
  end
end
