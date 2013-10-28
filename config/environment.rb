# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.18' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

# MySociety specific helper functions
$:.push(File.join(File.dirname(__FILE__), '../commonlib/rblib'))

# ... if these fail to include, you need the commonlib submodule from git

load "config.rb"
load "format.rb"
load "mapit.rb"
load "mask.rb"
load "url_mapper.rb"
load "util.rb"
load "validate.rb"
load "voting_area.rb"
load "autorotate_image.rb"


Rails::Initializer.run do |config|

  # Load intial mySociety config
  MySociety::Config.set_file(File.join(config.root_path, 'config', 'general.yml'), true)
  MySociety::Config.load_default

  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  config.autoload_paths += %W( #{RAILS_ROOT}/app/sweepers )

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set the schema format to sql
  config.active_record.schema_format :sql

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  config.i18n.load_path += Dir[File.join(RAILS_ROOT, 'config', 'locales', '**', '*.{rb,yml}')]

  # Set the cache store
  cache_base_dir = MySociety::Config.get('CACHE_PARENT_DIRECTORY', RAILS_ROOT)
  config.cache_store = :file_store, File.join(cache_base_dir, 'cache')

  # override default fieldWithError divs in model-associated forms
  config.action_view.field_error_proc = Proc.new{ |html_tag, instance| html_tag }

end


# Use an asset host setting so that the admin interface can always get css, images, js.
if (MySociety::Config.get("DOMAIN", "") != "")
    ActionController::Base.asset_host = MySociety::Config.get("ASSET_HOST", 'localhost:3000')
end

# Domain for URLs (so can work for scripts, not just web pages)
ActionMailer::Base.default_url_options[:host] = MySociety::Config.get("DOMAIN", 'localhost:3000')

# settings for exception notification
ExceptionNotification::Notifier.exception_recipients = MySociety::Config.get("BUGS_EMAIL", "")
ExceptionNotification::Notifier.sender_address = [MySociety::Config.get("BUGS_EMAIL", "")]
ExceptionNotification::Notifier.email_prefix = "[FixMyTransport] "
