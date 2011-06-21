namespace :cached_assets do  
  desc "Regenerate aggregate/cached files"
  task :regenerate => :environment do
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::AssetTagHelper
    include ApplicationHelper
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
    library_js_link
    main_js_link
  end
 end
