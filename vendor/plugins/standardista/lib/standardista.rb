Haml::Template::options.update({
  # this renders the proper DOCTYPE and affects how tags are rendered
  :format => :html4,
  
  # if you're one of the people who can't stand single quotes for attributes
  # :attr_wrapper => '"',
  
  # the equal sign ('=') can be set to always escape HTML
  # :escape_html => true,
  
  # to occasionally prevent escaping, use '!=':
  #   #foo!= render :partial => 'foo'
})

if ENV['RAILS_ENV'] == 'production'
  # HTML is whitespace-insensitive markup language;
  # I don't care if the tags are properly indented in production
  Haml::Template::options[:ugly] = true
  
  # minimal whitespace in CSS files
  Sass::Plugin.options[:style] = :compact
end

module Standardista
  def self.auto_escape_html
    Haml::Template::options[:escape_html] = true
  end
end
