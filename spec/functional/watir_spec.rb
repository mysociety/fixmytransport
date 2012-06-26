require 'spec_helper'
require 'rubygems'
require 'watir-webdriver'
require 'pry'
require 'net/http'

$top_level = File.expand_path(File.join(File.dirname(__FILE__), '..', '..'))
$server_script = File.join($top_level, 'script', 'server')
$log_filename = File.join($top_level, 'server-for-watir.log')

class TestServer

  def initialize
    @port = 3001
    STDERR.puts "Forking and starting server now..."
    @server_pid = fork
    unless @server_pid
      # Open a file to redirect the server's STDOUT and STDERR to:
      @log = File.open($log_filename, 'a')
      STDOUT.reopen @log
      STDERR.reopen @log
      # We're in the child process, so just exec script/server with
      # the test environment and a non-standard port:
      Dir.chdir $top_level
      exec $server_script, "-e", "test", "--port", @port.to_s
    end
  end

  def server_alive?
    raise "The server wasn't started yet" unless @server_pid
    begin
      Process.kill(0, @server_pid)
      STDERR.puts "Apparently the server is alive..."
    rescue Errno::ESRCH => e
      # Then the process didn't exist:
      return false
    end
    return true
  end

  def can_connect
    unless server_alive?
      raise "Server died"
    end
    begin
      res = Net::HTTP.start("localhost", @port.to_s) {|http|
        http.get('/')
      }
      STDERR.puts "Apparently could get / from the server"
    rescue Errno::ECONNREFUSED => e
      return false
    end
    return true
  end

  def wait_for_startup
    while not can_connect
      sleep(0.5)
    end
    return true
  end

  def stop
    Process.kill "INT", @server_pid
    Process.wait
  end

end

server = TestServer.new
server.wait_for_startup

# For testing purposes, just sleep for a while to give us a chance to
# poke at the server that's been started.  It seems to be functional
# throughout this loop.

for i in 1..10 do
  puts "Counting #{i}"
  sleep(20)
end

# At some point the server just exits - possibly the first time watir
# hits it?

begin

  describe "an installation of FixMyTransport" do

    before(:all) do
      @b = Watir::Browser.new :ff
      @base_url = 'http://localhost:3001'
    end

    it "should have a home page" do
      @b.goto @base_url
      @b.text.should match 'View recent issues'
    end

    # This method reports a problem at a bus stop in Edinburgh, and
    # leaves you at the pop-up login box:

    def report_bus_stop(subject, description)
      @b.goto @base_url
      l = @b.link(:text, "STOP or STATION")
      l.click

      # I don't know why we need to wait here - it seems from the
      # documentation that this shouldn't be necessary...
      @b.text_field(:id, 'name').wait_until_present

      @b.text.should match 'Where is it?'

      i = @b.text_field(:id, 'name')
      i.set('EH8 9NB')
      b = @b.button(:text, 'Go')
      b.click
      i = @b.element(:title, /Buccleuch Terrace.*opposite/)
      i.click
      @b.text.should match 'Send a message to the people responsible'
      @b.text.should match /To\s+City of Edinburgh Council/
      subject_field = @b.text_field :name => 'problem[subject]'
      subject_field.set subject
      category = @b.select_list :name => 'problem[category]'
      category.select 'Bus stops'
      description_field = @b.text_field :name => 'problem[description]'
      description_field.set description
      @b.button(:type => 'submit').click
    end


    it "should allow you to report a problem at a stop, creating a new account" do
      report_bus_stop('Imaginary problem',
                      'This is an imaginary problem for testing purposes')

      # Again, I don't know why we need to wait here - it seems from the
      # documentation that this shouldn't be necessary...
      @b.text_field(:name, 'user[name]').wait_until_present

      # Create an account:

      @b.text_field(:name => 'user[name]').set('Humphrey Appleby')
      @b.text_field(:name => 'user[email]').set('humpy@localhost')
      @b.text_field(:name => 'user[password]').set('p4ssw0rd')
      @b.text_field(:name => 'user[password_confirmation]').set('p4ssw0rd')
      @b.button(:text => 'Create Account').click

      @b.h2(:text => /Nearly Done/).wait_until_present

      @b.text.should match 'Nearly Done! Now check your email'

      # Now cheat, and fetch the confirmation token directly from the
      # user table:

      binding.pry

    end

    after(:all) do
      # @b.close
    end

  end

rescue Exception => e
  STDERR.puts "Stopping after exception #{e}"
ensure
  server.stop
end
