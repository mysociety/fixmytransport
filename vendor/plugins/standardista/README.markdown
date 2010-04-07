Standardista
============
Prove that you care for web standards. Use simple HTML 4 for output instead of pretending you know what XHTML really is.

Requirements
------------
Standardista is a set of options for [Haml 2.0](http://nex-3.com/posts/76-haml-2-0).

Include the Haml gem in your environment.rb:

    config.gem 'haml', :version => '~> 2.0'
  
Features
--------
* sets Haml output to HTML 4
* in production: sets Sass output to 'compact'
* in production: turns on Haml 'ugly' mode (faster rendering because it doesn't care for indenting)
* patches ActionView `tag` helper to stop generating self-closing tags

More to come.