Rake::Task["doc:app"].clear
Rake::Task["doc/app"].clear
Rake::Task["doc/app/index.html"].clear

namespace :doc do
    Rake::RDocTask.new('app') do |rdoc|
        rdoc.rdoc_dir = 'doc/app'
        rdoc.title    = 'FixMyTransport'
        rdoc.main     = 'doc/README' # define README as index

        rdoc.options << '--charset' << 'utf-8'

        rdoc.rdoc_files.include('app/**/*.rb')
        rdoc.rdoc_files.include('lib/**/*.rb')
        rdoc.rdoc_files.exclude('lib/ruby-msg/**/*.rb')
        rdoc.rdoc_files.exclude('lib/ruby-ole/**/*.rb')
        rdoc.rdoc_files.include('doc/README')

    end
end
