require File.dirname(__FILE__) +  '/data_loader'
require 'haml2erb'

namespace :temp do

  desc 'do the automated part of converting templates for a view directory'
  task :convert_templates => :environment do 
    check_for_dir
    dir = ENV['DIR']
    view_dir = File.join(RAILS_ROOT, 'app', 'views', dir)
    files = Dir.glob("#{view_dir}/*.haml")
    files.each do |file|
      text = File.read(file)
      basename = File.basename(file, '.haml')
      erb_file = File.open(File.join(RAILS_ROOT, 'app', 'views', dir, "#{basename}.erb"), 'w')
      system("mv #{file} #{file}.old")
      erb = Haml2Erb.convert(text)
      erb_file.write(erb)
      erb_file.close()
    end
  end
end
