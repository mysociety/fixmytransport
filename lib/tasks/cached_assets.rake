namespace :cached_assets do  
  
  def css_dir
    "#{RAILS_ROOT}/public/stylesheets/"
  end
  
  def js_dir
    "#{RAILS_ROOT}/public/javascripts/"
  end
  
  def js_files
    ['map', 'fixmytransport', 'fb', 'ie', 'geo', 'fmt_geo', 'admin']
  end
  
  def css_files
    ['core', 'map', 'buttons', 'ui-tabs-mod', 'fixmytransport', 'guides', 'ie67', 'ie678', 'ie9','no-js']
  end
  
  desc "Delete aggregate/cached files"
  task :regenerate => :environment do
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::AssetTagHelper
    include ApplicationHelper
    js_assets = ['admin_libraries', 'libraries', 'main']
    css_assets = ['main']
    js_assets.each do |basename|
      path = "#{js_dir}#{basename}.js"
      system("rm #{path}") if (File.exist?(path))
    end
    css_assets.each do |basename|
      path = "#{css_dir}#{basename}.css"
      system("rm #{path}") if (File.exist?(path))
    end
  end
  
  desc 'Clear minified asset files'
  task :clear_minified => :environment do 
    js_files.each do |basename|
      minified_filename = "#{js_dir}#{basename}.min.js"
      system("rm #{minified_filename}")
    end
    css_files.each do |basename|
      minified_filename = "#{css_dir}#{basename}.min.css"
      system("rm #{minified_filename}")
    end
  end
  
  desc 'Minify asset files'
  task :minify => :environment do 
    compressor_jar = MySociety::Config.get('YUI_COMPRESSOR_JAR', '')
    if compressor_jar == ''
      puts "No YUI_COMPRESSOR_JAR config parameter, exiting."
      exit(0)
    end
    js_files.each do |basename|
      asset_filename = "#{js_dir}#{basename}.js"
      minified_filename = "#{js_dir}#{basename}.min.js"
      system("java -jar #{compressor_jar} --type js -o #{minified_filename} #{asset_filename}")
    end
    css_files.each do |basename|
      asset_filename = "#{css_dir}#{basename}.css"
      minified_filename = "#{css_dir}#{basename}.min.css"
      system("java -jar #{compressor_jar} --type css -o #{minified_filename} #{asset_filename}")
    end
  end
  
 end
