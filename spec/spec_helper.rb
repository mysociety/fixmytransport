# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path(File.join(File.dirname(__FILE__),'..','config','environment'))
require 'spec/autorun'
require 'spec/rails'

# Uncomment the next line to use webrat's matchers
#require 'webrat/integrations/rspec-rails'
require 'spec/shared/transport_location_helpers'
require 'spec/shared/controller_helpers'
require 'spec/shared/data_generation_helper'
require 'spec/initializers/actionmailer_smtp_format_patch_spec'
# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = false
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  config.before(:each) do
    # make sure we don't call the live API when running tests
    MySociety::MaPit.stub!(:call).and_return({})
  end

  config.before(:each, :type => :controller) do
    # have all controllers act as if in 'live' status by default
    @controller.stub!(:app_status).and_return('live')

    # mock up an admin authorized user for admin controller specs (except the user_sessions controller,
    # which does it's own mocking)
    if @controller.is_a?(Admin::AdminController) && !@controller.is_a?(Admin::UserSessionsController)
      @user = mock_model(User, :is_admin? => true,
                               :suspended? => false,
                               :can_admin? => true)
      controller.stub!(:current_user).and_return(@user)
    end
  end

end

def default_fixtures
  [:transport_modes,
   :localities,
   :locality_links,
   :stop_types,
   :stop_area_types,
   :transport_mode_stop_types,
   :transport_mode_stop_area_types,
   :stops,
   :stop_areas,
   :regions,
   :routes,
   :route_sub_routes,
   :sub_routes,
   :journey_patterns,
   :stop_area_memberships,
   :stop_area_links,
   :route_segments,
   :operators,
   :route_operators,
   :route_source_admin_areas,
   :route_localities,
   :admin_areas,
   :route_source_admin_areas]
end
