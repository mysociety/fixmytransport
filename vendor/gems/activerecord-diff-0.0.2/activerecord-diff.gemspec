# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_record_diff/version"

Gem::Specification.new do |s|
  s.name        = "activerecord-diff"
  s.version     = ActiveRecordDiff::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Stephen Prater"]
  s.email       = ["stephenp@agrussell.com"]
  s.homepage    = "http://github.com/agrussellknives/activerecord-diff"
  s.summary     = %q{Gemify Simple diff for ActiveRecord objects.}
  s.description = %q{Simple diff for ActiveRecord }

  s.rubyforge_project = "activerecord-diff"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency('activerecord')
  s.add_dependency('activesupport')

  s.add_development_dependency('bundler')
  s.add_development_dependency('rake')
  s.add_development_dependency('sqlite3-ruby')
end
