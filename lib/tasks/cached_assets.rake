namespace :cached_assets do  
  desc "Regenerate aggregate/cached files"
  task :regenerate => :environment do
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::AssetTagHelper
    js_dir = "#{RAILS_ROOT}/public/javascripts/"
    css_dir = "#{RAILS_ROOT}/public/stylesheets/"
    js_assets = ['libraries', 'main']
    css_assets = ['main']
    js_assets.each do |basename|
      path = "#{js_dir}#{basename}.js"
      system("rm #{path}") if (File.exist?(path))
    end
    css_assets.each do |basename|
      path = "#{css_dir}#{basename}.css"
      system("rm #{path}") if (File.exist?(path))
    end
    stylesheet_link_tag('core', 'fixmytransport', 'map', 'buttons', :cache => 'main')
    javascript_include_tag('fixmytransport', 'application', :charset => 'utf-8', :cache => 'main') 
    javascript_include_tag('jquery-1.5.2.min', 'jquery-ui-1.8.13.custom.min', 'jquery.autofill.min', 'jquery.form.min', :charset => 'utf-8', :cache => 'libraries')
  end
 end
