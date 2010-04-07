begin
  gem 'haml', '>= 2.0'
rescue Gem::LoadError
  $stderr.puts 'Standardista plugin needs Haml 2.0 or newer.'
end