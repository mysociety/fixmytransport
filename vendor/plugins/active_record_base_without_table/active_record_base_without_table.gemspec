VERSION = '0.1.2'

Gem::Specification.new do |s|
  s.name = "active_record_base_without_table"
  s.version = VERSION
  s.authors = [ "Jonathan Viney", "Dmitry Ratnikov" ]
  s.homepage = 'http://github.com/ratnikov/active_record_base_without_table/tree/master'
  s.date = Time.now
  s.email = 'ratnikov@gmail.com'
  s.has_rdoc = false
  s.summary = "Allows to use ActiveRecord::Base functionality without database table"

  files = [ 'lib/active_record_base_without_table.rb', 'lib/active_record/base_without_table.rb']
  
  s.files = files

  s.require_path = 'lib'
end
