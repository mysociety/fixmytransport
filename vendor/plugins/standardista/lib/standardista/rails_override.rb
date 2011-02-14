module Standardista
  module TagHelper
    # override tag helper from Rails to disable self-closing tags
    def tag(name, options = nil, open = false, escape = true)
      tag_string = "<#{name}#{tag_options(options, escape) if options}>"
      tag_string.respond_to?('html_safe') ? tag_string.html_safe : tag_string
    end
  end
end

ActionView::Base.send :include, Standardista::TagHelper

# unfortunately, this duplication seems necessary :(
ActionView::Helpers::InstanceTag.class_eval do
  def tag_without_error_wrapping(name, options = nil, open = false, escape = true)
    tag_string = "<#{name}#{tag_options(options, escape) if options}>"
    tag_string.respond_to?('html_safe') ? tag_string.html_safe : tag_string
  end
end
