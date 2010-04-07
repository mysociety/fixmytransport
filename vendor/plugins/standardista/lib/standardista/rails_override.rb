module Standardista
  module TagHelper
    # override tag helper from Rails to disable self-closing tags
    def tag(name, options = nil, open = false, escape = true)
      "<#{name}#{tag_options(options, escape) if options}>"
    end
  end
end

ActionView::Base.send :include, Standardista::TagHelper

# unfortunately, this duplication seems necessary :(
ActionView::Helpers::InstanceTag.class_eval do
  def tag_without_error_wrapping(name, options = nil, open = false, escape = true)
    "<#{name}#{tag_options(options, escape) if options}>"
  end
end
